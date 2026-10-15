-- Online payment on the website (Stripe Checkout); cash on delivery stays as before.
--   * the website calls the create-checkout-session Edge Function, which runs
--     start_card_checkout() as the customer: same checks and menu prices as
--     place_website_order(), saved as a website_payments row (no order yet)
--   * the customer pays on Stripe's page; the stripe-webhook Edge Function then
--     calls complete_card_checkout(), which creates the real order as Online / Paid
--   * so the desktop only ever sees online orders that are already paid

-- ── Card checkouts waiting for Stripe ─────────────────────────────────────
create table if not exists public.website_payments (
  id                uuid primary key default gen_random_uuid(),
  branch_id         uuid not null,
  customer_user_id  uuid not null references auth.users(id) on delete cascade,
  delivery          boolean not null,
  customer_name     text not null,
  customer_phone    text not null,
  address           text not null default '',
  notes             text not null default '',
  lines             jsonb not null,  -- priced lines, same shape place_website_order() builds
  amount            numeric not null,
  stripe_session_id text unique,
  status            text not null default 'open' check (status in ('open', 'paid', 'expired')),
  order_number      text,
  created_at        timestamptz not null default now(),
  paid_at           timestamptz
);
create index if not exists website_payments_customer_idx on public.website_payments (customer_user_id);

-- Customers read their own rows (the website waits for status = 'paid');
-- every write goes through the functions below.
alter table public.website_payments enable row level security;
drop policy if exists customer_own_payments on public.website_payments;
create policy customer_own_payments on public.website_payments for select to authenticated
  using (customer_user_id = (select auth.uid()));

do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'website_payments'
  ) then
    alter publication supabase_realtime add table public.website_payments;
  end if;
end $$;

-- ── Shared checks and pricing (internal) ──────────────────────────────────
create or replace function public.check_website_order_details(
  p_delivery boolean,
  p_customer_name text,
  p_customer_phone text,
  p_address text
) returns void
language plpgsql immutable set search_path = '' as $$
begin
  if coalesce(trim(p_customer_name), '') = '' or coalesce(trim(p_customer_phone), '') = '' then
    raise exception 'Name and phone are required';
  end if;
  if p_delivery and coalesce(trim(p_address), '') = '' then
    raise exception 'Delivery address is required';
  end if;
end;
$$;

-- p_items: [{"menu_item_id": "<uuid>", "size": "Large" | "", "qty": 2}, ...]
-- Returns the priced lines; prices are read from the menu, never from the website.
create or replace function public.price_website_items(p_items jsonb)
returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare
  v_branch uuid := public.website_branch_id();
  v_item   jsonb;
  v_menu   record;
  v_price  numeric;
  v_qty    int;
  v_size   text;
  v_lines  jsonb := '[]'::jsonb;
begin
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Your cart is empty';
  end if;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty  := (v_item->>'qty')::int;
    v_size := coalesce(v_item->>'size', '');
    if v_qty is null or v_qty < 1 or v_qty > 99 then
      raise exception 'Invalid quantity';
    end if;

    select id, name, price into v_menu from public.menu_items
    where id = (v_item->>'menu_item_id')::uuid and branch_id = v_branch and is_available;
    if not found then
      raise exception 'An item in your cart is no longer available';
    end if;

    if v_size = '' then
      v_price := v_menu.price;
    else
      select s.price into v_price from public.menu_item_sizes s
      where s.menu_item_id = v_menu.id and s.name = v_size;
      if not found then
        raise exception 'Size "%" is not available for %', v_size, v_menu.name;
      end if;
    end if;

    v_lines := v_lines || jsonb_build_object(
      'menu_item_id', v_menu.id,
      'item_name',    case when v_size = '' then v_menu.name else v_menu.name || ' (' || v_size || ')' end,
      'size',         v_size,
      'unit_price',   v_price,
      'qty',          v_qty,
      'total_price',  v_price * v_qty
    );
  end loop;

  return v_lines;
end;
$$;

-- Creates the order (+ delivery row) from priced lines and returns its number.
create or replace function public.insert_website_order(
  p_uid uuid,
  p_delivery boolean,
  p_customer_name text,
  p_customer_phone text,
  p_address text,
  p_notes text,
  p_lines jsonb,
  p_paid_by_card boolean
) returns text
language plpgsql security definer set search_path = '' as $$
declare
  v_branch   uuid := public.website_branch_id();
  v_number   text;
  v_order_id uuid;
  v_subtotal numeric;
  v_summary  text;
begin
  select coalesce(sum((l->>'total_price')::numeric), 0) into v_subtotal
  from jsonb_array_elements(p_lines) l;

  -- Next order number, same format as the POS (#1001, #1002, ...).
  perform pg_advisory_xact_lock(hashtext('order_number:' || v_branch::text));
  select '#' || (coalesce(max(nullif(regexp_replace(order_number, '\D', '', 'g'), '')::int), 1000) + 1)
    into v_number
  from public.orders where branch_id = v_branch;

  insert into public.orders (
    branch_id, order_number, order_type, customer_type, customer_name, customer_phone,
    table_number, status, payment_method, payment_status,
    subtotal, discount_pct, discount_flat, discount_amt, tax_pct, tax_amt, total, notes,
    customer_user_id
  ) values (
    v_branch, v_number, case when p_delivery then 'Delivery' else 'Takeaway' end, 'Online',
    trim(p_customer_name), trim(p_customer_phone),
    '', 'pending',
    case when p_paid_by_card then 'Online' else 'Cash' end,
    case when p_paid_by_card then 'Paid' else 'Unpaid' end,
    v_subtotal, 0, 0, 0, 0, 0, v_subtotal,
    concat_ws(' • ', 'Online order (website)',
      case when p_paid_by_card then 'Paid online' end,
      case when p_delivery then 'Address: ' || trim(p_address) end,
      nullif(trim(p_notes), '')),
    p_uid
  ) returning id into v_order_id;

  insert into public.order_items (order_id, branch_id, menu_item_id, item_name, item_emoji, size, unit_price, qty, total_price)
  select v_order_id, v_branch, (l->>'menu_item_id')::uuid, l->>'item_name', '', l->>'size',
         (l->>'unit_price')::numeric, (l->>'qty')::int, (l->>'total_price')::numeric
  from jsonb_array_elements(p_lines) l;

  if p_delivery then
    select string_agg((l->>'item_name') || ' × ' || (l->>'qty'), ', ') into v_summary
    from jsonb_array_elements(p_lines) l;

    insert into public.delivery_orders (branch_id, order_id, order_num, customer_name, phone, address, items, amount, notes, status)
    values (v_branch, v_order_id, v_number, trim(p_customer_name), trim(p_customer_phone), trim(p_address),
            v_summary, v_subtotal,
            -- The rider must not collect cash for an order that is already paid.
            concat_ws(' • ',
              case when p_paid_by_card then 'PAID ONLINE - do not collect cash' end,
              nullif(trim(p_notes), '')),
            'pending');
  end if;

  return v_number;
end;
$$;

revoke all on function public.check_website_order_details(boolean, text, text, text) from public, anon, authenticated;
revoke all on function public.price_website_items(jsonb) from public, anon, authenticated;
revoke all on function public.insert_website_order(uuid, boolean, text, text, text, text, jsonb, boolean) from public, anon, authenticated;

-- ── Cash orders: same behaviour as before, now built from the shared parts ─
create or replace function public.place_website_order(
  p_delivery boolean,
  p_customer_name text,
  p_customer_phone text,
  p_address text,
  p_notes text,
  p_items jsonb
) returns text
language plpgsql security definer set search_path = '' as $$
declare
  v_uid uuid := auth.uid();
begin
  if v_uid is null then
    raise exception 'Please log in to place an order' using errcode = '42501';
  end if;
  perform public.check_website_order_details(p_delivery, p_customer_name, p_customer_phone, p_address);
  return public.insert_website_order(
    v_uid, p_delivery, p_customer_name, p_customer_phone, p_address, p_notes,
    public.price_website_items(p_items), false);
end;
$$;

revoke all on function public.place_website_order(boolean, text, text, text, text, jsonb) from public, anon;
grant execute on function public.place_website_order(boolean, text, text, text, text, jsonb) to authenticated;

-- ── Card orders, step 1: price the cart and remember it ───────────────────
-- Called by create-checkout-session as the signed-in customer.
-- Returns {"payment_id", "amount", "lines"} for building the Stripe session.
create or replace function public.start_card_checkout(
  p_delivery boolean,
  p_customer_name text,
  p_customer_phone text,
  p_address text,
  p_notes text,
  p_items jsonb
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid    uuid := auth.uid();
  v_lines  jsonb;
  v_amount numeric;
  v_id     uuid;
begin
  if v_uid is null then
    raise exception 'Please log in to place an order' using errcode = '42501';
  end if;
  perform public.check_website_order_details(p_delivery, p_customer_name, p_customer_phone, p_address);
  v_lines := public.price_website_items(p_items);
  select sum((l->>'total_price')::numeric) into v_amount from jsonb_array_elements(v_lines) l;
  -- Stripe's minimum charge in GBP.
  if v_amount < 0.30 then
    raise exception 'Online payment needs an order of at least £0.30';
  end if;

  insert into public.website_payments (
    branch_id, customer_user_id, delivery, customer_name, customer_phone, address, notes, lines, amount
  ) values (
    public.website_branch_id(), v_uid, p_delivery, trim(p_customer_name), trim(p_customer_phone),
    case when p_delivery then trim(p_address) else '' end, coalesce(trim(p_notes), ''), v_lines, v_amount
  ) returning id into v_id;

  return jsonb_build_object('payment_id', v_id, 'amount', v_amount, 'lines', v_lines);
end;
$$;

revoke all on function public.start_card_checkout(boolean, text, text, text, text, jsonb) from public, anon;
grant execute on function public.start_card_checkout(boolean, text, text, text, text, jsonb) to authenticated;

-- ── Card orders, step 2: Stripe says it's paid → create the order ─────────
-- Called only by stripe-webhook (service role). Safe to call twice: Stripe
-- may resend the same event.
create or replace function public.complete_card_checkout(
  p_payment_id uuid,
  p_session_id text,
  p_amount_pence bigint
) returns text
language plpgsql security definer set search_path = '' as $$
declare
  v_pay      public.website_payments%rowtype;
  v_expected bigint;
  v_number   text;
begin
  select * into v_pay from public.website_payments where id = p_payment_id for update;
  if v_pay.id is null then
    raise exception 'Unknown card checkout %', p_payment_id;
  end if;
  if v_pay.status = 'paid' then
    return v_pay.order_number;
  end if;
  if v_pay.stripe_session_id is distinct from p_session_id then
    raise exception 'Stripe session does not match card checkout %', p_payment_id;
  end if;

  -- Same rounding create-checkout-session uses for the Stripe line items.
  select sum(round((l->>'unit_price')::numeric * 100) * (l->>'qty')::int) into v_expected
  from jsonb_array_elements(v_pay.lines) l;
  if v_expected <> p_amount_pence then
    raise exception 'Paid amount % does not match order amount % (card checkout %)',
      p_amount_pence, v_expected, p_payment_id;
  end if;

  v_number := public.insert_website_order(
    v_pay.customer_user_id, v_pay.delivery, v_pay.customer_name, v_pay.customer_phone,
    v_pay.address, v_pay.notes, v_pay.lines, true);

  update public.website_payments
  set status = 'paid', order_number = v_number, paid_at = now()
  where id = v_pay.id;

  return v_number;
end;
$$;

revoke all on function public.complete_card_checkout(uuid, text, bigint) from public, anon, authenticated;
grant execute on function public.complete_card_checkout(uuid, text, bigint) to service_role;
