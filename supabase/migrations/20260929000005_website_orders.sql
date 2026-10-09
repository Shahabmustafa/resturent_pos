-- Step 5: customer website.
--   * anyone can read the website branch's menu (categories, items, sizes)
--   * signed-in customers place orders through place_website_order()
--   * customers can read only their own orders ("My Orders" on the website)
--   * only POS staff can change menu/receipt images in storage

-- ── Which branch the website serves ───────────────────────────────────────
-- Keep in sync with kWebsiteBranchId in lib/feature/customer_app/data/menu_data.dart.
create or replace function public.website_branch_id()
returns uuid language sql immutable set search_path = '' as $$
  select 'f9222fe0-3356-4473-883f-d38f192d0efb'::uuid  -- Pizza Hub 2
$$;
grant execute on function public.website_branch_id() to anon, authenticated;

-- ── Public menu ───────────────────────────────────────────────────────────
drop policy if exists website_menu_read on public.categories;
create policy website_menu_read on public.categories for select to anon, authenticated
  using (branch_id = public.website_branch_id());

drop policy if exists website_menu_read on public.menu_items;
create policy website_menu_read on public.menu_items for select to anon, authenticated
  using (branch_id = public.website_branch_id() and is_available);

drop policy if exists website_menu_read on public.menu_item_sizes;
create policy website_menu_read on public.menu_item_sizes for select to anon, authenticated
  using (exists (
    select 1 from public.menu_items m
    where m.id = menu_item_id and m.branch_id = public.website_branch_id() and m.is_available
  ));

-- ── Link orders to website customers ──────────────────────────────────────
alter table public.orders
  add column if not exists customer_user_id uuid references auth.users(id) on delete set null;
create index if not exists orders_customer_user_id_idx on public.orders (customer_user_id);

drop policy if exists customer_own_orders on public.orders;
create policy customer_own_orders on public.orders for select to authenticated
  using (customer_user_id = (select auth.uid()));

drop policy if exists customer_own_order_items on public.order_items;
create policy customer_own_order_items on public.order_items for select to authenticated
  using (exists (
    select 1 from public.orders o
    where o.id = order_id and o.customer_user_id = (select auth.uid())
  ));

-- ── Place an order from the website ───────────────────────────────────────
-- p_items: [{"menu_item_id": "<uuid>", "size": "Large" | "", "qty": 2}, ...]
-- Prices are read from the menu here; the website never sends prices.
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
  v_uid      uuid := auth.uid();
  v_branch   uuid := public.website_branch_id();
  v_number   text;
  v_order_id uuid;
  v_subtotal numeric := 0;
  v_item     jsonb;
  v_menu     record;
  v_price    numeric;
  v_qty      int;
  v_size     text;
  v_lines    jsonb := '[]'::jsonb;
  v_summary  text;
begin
  if v_uid is null then
    raise exception 'Please log in to place an order' using errcode = '42501';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Your cart is empty';
  end if;
  if coalesce(trim(p_customer_name), '') = '' or coalesce(trim(p_customer_phone), '') = '' then
    raise exception 'Name and phone are required';
  end if;
  if p_delivery and coalesce(trim(p_address), '') = '' then
    raise exception 'Delivery address is required';
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

  insert into public.orders (
    branch_id, order_number, order_type, customer_type, customer_name, customer_phone,
    table_number, status, payment_method, payment_status,
    subtotal, discount_pct, discount_flat, discount_amt, tax_pct, tax_amt, total, notes,
    customer_user_id
  ) values (
    v_branch, v_number, case when p_delivery then 'Delivery' else 'Takeaway' end, 'Online',
    trim(p_customer_name), trim(p_customer_phone),
    '', 'pending', 'Cash', 'Unpaid',
    v_subtotal, 0, 0, 0, 0, 0, v_subtotal,
    concat_ws(' • ', 'Online order (website)',
      case when p_delivery then 'Address: ' || trim(p_address) end,
      nullif(trim(p_notes), '')),
    v_uid
  ) returning id into v_order_id;

  insert into public.order_items (order_id, branch_id, menu_item_id, item_name, item_emoji, size, unit_price, qty, total_price)
  select v_order_id, v_branch, (l->>'menu_item_id')::uuid, l->>'item_name', '', l->>'size',
         (l->>'unit_price')::numeric, (l->>'qty')::int, (l->>'total_price')::numeric
  from jsonb_array_elements(v_lines) l;

  if p_delivery then
    select string_agg((l->>'item_name') || ' × ' || (l->>'qty'), ', ') into v_summary
    from jsonb_array_elements(v_lines) l;

    insert into public.delivery_orders (branch_id, order_id, order_num, customer_name, phone, address, items, amount, notes, status)
    values (v_branch, v_order_id, v_number, trim(p_customer_name), trim(p_customer_phone), trim(p_address),
            v_summary, v_subtotal, coalesce(trim(p_notes), ''), 'pending');
  end if;

  return v_number;
end;
$$;

revoke all on function public.place_website_order(boolean, text, text, text, text, jsonb) from public, anon;
grant execute on function public.place_website_order(boolean, text, text, text, text, jsonb) to authenticated;

-- ── Storage: website customers are signed in too, so limit writes to staff ──
create or replace function public.is_pos_staff()
returns boolean language sql stable security definer set search_path = '' as $$
  select public.my_branch_id() is not null or public.my_company_id() is not null
$$;
revoke all on function public.is_pos_staff() from public, anon;
grant execute on function public.is_pos_staff() to authenticated;

drop policy if exists "POS users upload images" on storage.objects;
drop policy if exists "POS users update images" on storage.objects;
drop policy if exists "POS users delete images" on storage.objects;

create policy "POS users upload images" on storage.objects for insert to authenticated
  with check (bucket_id in ('menu-images', 'receipt_image') and public.is_pos_staff());
create policy "POS users update images" on storage.objects for update to authenticated
  using (bucket_id in ('menu-images', 'receipt_image') and public.is_pos_staff());
create policy "POS users delete images" on storage.objects for delete to authenticated
  using (bucket_id in ('menu-images', 'receipt_image') and public.is_pos_staff());
