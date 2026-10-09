-- Table QR ordering.
--   * every table gets a secret qr_token; its QR code opens the website at ?table=<token>
--   * anyone at the table (no login needed) can see which table they are at and
--     send an order through place_table_order()
--   * the order lands on the desktop as an unpaid Dine-in order for that table
--     and the table is marked reserved; marking it Paid in Orders frees the table

-- ── Secret token per table ────────────────────────────────────────────────
-- Random, so a table's QR can't be guessed from its number.
alter table public.tables
  add column if not exists qr_token text not null default replace(gen_random_uuid()::text, '-', '');
create unique index if not exists tables_qr_token_key on public.tables (qr_token);

-- ── Which table a QR belongs to ────────────────────────────────────────────
create or replace function public.table_for_qr(p_token text)
returns text language sql stable security definer set search_path = '' as $$
  select t.table_number::text from public.tables t
  where t.qr_token = p_token and t.is_active and t.branch_id = public.website_branch_id()
$$;
revoke all on function public.table_for_qr(text) from public;
grant execute on function public.table_for_qr(text) to anon, authenticated;

-- ── Place an order from a table ───────────────────────────────────────────
-- p_items: [{"menu_item_id": "<uuid>", "size": "Large" | "", "qty": 2}, ...]
-- Prices are read from the menu here; the website never sends prices.
create or replace function public.place_table_order(
  p_token text,
  p_customer_name text,
  p_notes text,
  p_items jsonb
) returns text
language plpgsql security definer set search_path = '' as $$
declare
  v_branch   uuid := public.website_branch_id();
  v_table    public.tables%rowtype;
  v_number   text;
  v_order_id uuid;
  v_subtotal numeric := 0;
  v_item     jsonb;
  v_menu     record;
  v_price    numeric;
  v_qty      int;
  v_size     text;
  v_lines    jsonb := '[]'::jsonb;
begin
  select * into v_table from public.tables
  where qr_token = p_token and is_active and branch_id = v_branch;
  if v_table.id is null then
    raise exception 'This table QR code is not valid. Please ask the staff for help.';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Your cart is empty';
  end if;
  -- A photo of the QR shouldn't be enough to flood the kitchen.
  if (select count(*) from public.orders
      where branch_id = v_branch and table_number = v_table.table_number
        and created_at > now() - interval '10 minutes') >= 5 then
    raise exception 'Too many orders from this table. Please ask the staff for help.';
  end if;

  -- Price every line from the database.
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

    v_subtotal := v_subtotal + v_price * v_qty;
    v_lines := v_lines || jsonb_build_object(
      'menu_item_id', v_menu.id,
      'item_name',    case when v_size = '' then v_menu.name else v_menu.name || ' (' || v_size || ')' end,
      'size',         v_size,
      'unit_price',   v_price,
      'qty',          v_qty,
      'total_price',  v_price * v_qty
    );
  end loop;

  -- Next order number, same format as the POS (#1001, #1002, ...).
  perform pg_advisory_xact_lock(hashtext('order_number:' || v_branch::text));
  select '#' || (coalesce(max(nullif(regexp_replace(order_number, '\D', '', 'g'), '')::int), 1000) + 1)
    into v_number
  from public.orders where branch_id = v_branch;

  -- customer_type 'Online' so the desktop's new-order alert picks it up.
  insert into public.orders (
    branch_id, order_number, order_type, customer_type, customer_name, customer_phone,
    table_number, status, payment_method, payment_status,
    subtotal, discount_pct, discount_flat, discount_amt, tax_pct, tax_amt, total, notes,
    customer_user_id
  ) values (
    v_branch, v_number, 'Dine-in', 'Online',
    coalesce(nullif(trim(p_customer_name), ''), 'Table ' || v_table.table_number), '',
    v_table.table_number, 'pending', 'Cash', 'Unpaid',
    v_subtotal, 0, 0, 0, 0, 0, v_subtotal,
    concat_ws(' • ', 'Table QR order', nullif(trim(p_notes), '')),
    auth.uid()  -- signed-in customers also see it under My Orders
  ) returning id into v_order_id;

  insert into public.order_items (order_id, branch_id, menu_item_id, item_name, item_emoji, size, unit_price, qty, total_price)
  select v_order_id, v_branch, (l->>'menu_item_id')::uuid, l->>'item_name', '', l->>'size',
         (l->>'unit_price')::numeric, (l->>'qty')::int, (l->>'total_price')::numeric
  from jsonb_array_elements(v_lines) l;

  update public.tables set status = 'reserved', updated_at = now() where id = v_table.id;

  return v_number;
end;
$$;

revoke all on function public.place_table_order(text, text, text, jsonb) from public;
grant execute on function public.place_table_order(text, text, text, jsonb) to anon, authenticated;
