-- Delivery charge for website delivery orders.
--   * set on the desktop: Settings → Company Info → Delivery (branches.delivery_fee)
--   * the website shows it at checkout (website_delivery_fee()), but the order
--     functions add it on the server, so the website never decides the amount
--   * saved on the order as orders.delivery_fee; total = subtotal + delivery_fee
--   * takeaway and table orders have no delivery charge

alter table public.branches add column if not exists delivery_fee numeric not null default 0;
alter table public.branches drop constraint if exists branches_delivery_fee_check;
alter table public.branches add constraint branches_delivery_fee_check check (delivery_fee >= 0);

alter table public.orders add column if not exists delivery_fee numeric not null default 0;
-- A card checkout keeps the charge it was started with, so the order matches what Stripe charged.
alter table public.website_payments add column if not exists delivery_fee numeric not null default 0;

-- ── The website's delivery charge (public, shown at checkout) ─────────────
create or replace function public.website_delivery_fee()
returns numeric language sql stable security definer set search_path = '' as $$
  select coalesce((select b.delivery_fee from public.branches b where b.id = public.website_branch_id()), 0)
$$;
revoke all on function public.website_delivery_fee() from public;
grant execute on function public.website_delivery_fee() to anon, authenticated;

-- ── Order insert now takes the delivery charge ────────────────────────────
drop function if exists public.insert_website_order(uuid, boolean, text, text, text, text, jsonb, boolean);

create function public.insert_website_order(
  p_uid uuid,
  p_delivery boolean,
  p_customer_name text,
  p_customer_phone text,
  p_address text,
  p_notes text,
  p_lines jsonb,
  p_paid_by_card boolean,
  p_delivery_fee numeric
) returns text
language plpgsql security definer set search_path = '' as $$
declare
  v_branch   uuid := public.website_branch_id();
  v_fee      numeric := case when p_delivery then greatest(coalesce(p_delivery_fee, 0), 0) else 0 end;
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
    subtotal, discount_pct, discount_flat, discount_amt, tax_pct, tax_amt, delivery_fee, total, notes,
    customer_user_id
  ) values (
    v_branch, v_number, case when p_delivery then 'Delivery' else 'Takeaway' end, 'Online',
    trim(p_customer_name), trim(p_customer_phone),
    '', 'pending',
    case when p_paid_by_card then 'Online' else 'Cash' end,
    case when p_paid_by_card then 'Paid' else 'Unpaid' end,
    v_subtotal, 0, 0, 0, 0, 0, v_fee, v_subtotal + v_fee,
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
            v_summary, v_subtotal + v_fee,
            -- The rider must not collect cash for an order that is already paid.
            concat_ws(' • ',
              case when p_paid_by_card then 'PAID ONLINE - do not collect cash' end,
              nullif(trim(p_notes), '')),
            'pending');
  end if;

  return v_number;
end;
$$;

revoke all on function public.insert_website_order(uuid, boolean, text, text, text, text, jsonb, boolean, numeric) from public, anon, authenticated;

-- ── Cash on delivery: charge added from the POS setting ───────────────────
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
    public.price_website_items(p_items), false, public.website_delivery_fee());
end;
$$;

-- ── Online payment, step 1: charge included in the amount Stripe takes ────
-- Returns {"payment_id", "amount", "delivery_fee", "lines"}.
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
  v_fee    numeric := case when p_delivery then public.website_delivery_fee() else 0 end;
  v_amount numeric;
  v_id     uuid;
begin
  if v_uid is null then
    raise exception 'Please log in to place an order' using errcode = '42501';
  end if;
  perform public.check_website_order_details(p_delivery, p_customer_name, p_customer_phone, p_address);
  v_lines := public.price_website_items(p_items);
  select sum((l->>'total_price')::numeric) + v_fee into v_amount from jsonb_array_elements(v_lines) l;
  -- Stripe's minimum charge in GBP.
  if v_amount < 0.30 then
    raise exception 'Online payment needs an order of at least £0.30';
  end if;

  insert into public.website_payments (
    branch_id, customer_user_id, delivery, customer_name, customer_phone, address, notes, lines, delivery_fee, amount
  ) values (
    public.website_branch_id(), v_uid, p_delivery, trim(p_customer_name), trim(p_customer_phone),
    case when p_delivery then trim(p_address) else '' end, coalesce(trim(p_notes), ''), v_lines, v_fee, v_amount
  ) returning id into v_id;

  return jsonb_build_object('payment_id', v_id, 'amount', v_amount, 'delivery_fee', v_fee, 'lines', v_lines);
end;
$$;

-- ── Online payment, step 2: order created with the same charge ────────────
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
  select sum(round((l->>'unit_price')::numeric * 100) * (l->>'qty')::int) + round(v_pay.delivery_fee * 100)
    into v_expected
  from jsonb_array_elements(v_pay.lines) l;
  if v_expected <> p_amount_pence then
    raise exception 'Paid amount % does not match order amount % (card checkout %)',
      p_amount_pence, v_expected, p_payment_id;
  end if;

  v_number := public.insert_website_order(
    v_pay.customer_user_id, v_pay.delivery, v_pay.customer_name, v_pay.customer_phone,
    v_pay.address, v_pay.notes, v_pay.lines, true, v_pay.delivery_fee);

  update public.website_payments
  set status = 'paid', order_number = v_number, paid_at = now()
  where id = v_pay.id;

  return v_number;
end;
$$;
