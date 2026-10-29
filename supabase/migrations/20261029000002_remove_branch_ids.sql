-- One restaurant, one branch: drop branch_id from every table.
-- The branches table stays (single row) and still carries the restaurant settings.
-- A copy of the old data is in schema backup_branch.

drop table public.tables_backup; -- a copy is kept in backup_branch

-- ── Staff helpers no longer depend on branch_users.branch_id ──────────────
create or replace function public.my_branch_id() returns uuid
language sql stable security definer set search_path = '' as $$
  select b.id from public.branches b
  where exists (select 1 from public.branch_users bu
                where bu.auth_user_id = (select auth.uid()) and bu.status = 'active')
  order by b.created_at limit 1
$$;

create or replace function public.is_pos_staff() returns boolean
language sql stable security definer set search_path = '' as $$
  select exists (select 1 from public.branch_users bu
                 where bu.auth_user_id = (select auth.uid()) and bu.status = 'active')
      or public.my_company_id() is not null
$$;

-- ── Policies that mention branch_id ───────────────────────────────────────
drop policy branch_access on public.branch_cash;
drop policy branch_access on public.branch_tax_settings;
drop policy branch_access on public.branch_tax_slabs;
drop policy branch_users_select on public.branch_users;
drop policy branch_users_update on public.branch_users;
drop policy branch_read on public.cash_counter_entries;
drop policy branch_read on public.cash_counters;
drop policy branch_access on public.cash_transactions;
drop policy branch_access on public.categories;
drop policy website_menu_read on public.categories;
drop policy branch_access on public.customers;
drop policy branch_access on public.deal_items;
drop policy branch_access on public.deal_sizes;
drop policy branch_access on public.deals;
drop policy branch_access on public.delivery_orders;
drop policy branch_access on public.menu_item_ingredients;
drop policy branch_access on public.menu_item_sizes;
drop policy website_menu_read on public.menu_item_sizes;
drop policy branch_access on public.menu_items;
drop policy website_menu_read on public.menu_items;
drop policy staff_feedback_delete on public.order_feedback;
drop policy staff_feedback_read on public.order_feedback;
drop policy website_feedback_read on public.order_feedback;
drop policy branch_access on public.order_items;
drop policy branch_access on public.orders;
drop policy branch_access on public.receipt_settings;
drop policy branch_access on public.riders;
drop policy branch_access on public.stock_items;
drop policy branch_access on public.supplier_transactions;
drop policy branch_access on public.suppliers;

-- ── Drop the columns ──────────────────────────────────────────────────────
alter table public.app_users              drop column branch_id;
alter table public.branch_cash            drop column branch_id;
alter table public.branch_tax_settings    drop column branch_id;
alter table public.branch_tax_slabs       drop column branch_id;
alter table public.branch_users           drop column branch_id;
alter table public.cash_counter_entries   drop column branch_id;
alter table public.cash_counters          drop column branch_id;
alter table public.cash_transactions      drop column branch_id;
alter table public.categories             drop column branch_id;
alter table public.customers              drop column branch_id;
alter table public.deals                  drop column branch_id;
alter table public.delivery_orders        drop column branch_id;
alter table public.menu_item_ingredients  drop column branch_id;
alter table public.menu_items             drop column branch_id;
alter table public.order_feedback         drop column branch_id;
alter table public.order_items            drop column branch_id;
alter table public.orders                 drop column branch_id;
alter table public.receipt_settings       drop column branch_id;
alter table public.riders                 drop column branch_id;
alter table public.stock_items            drop column branch_id;
alter table public.supplier_transactions  drop column branch_id;
alter table public.suppliers              drop column branch_id;
alter table public.website_payments       drop column branch_id;

-- ── Indexes the old columns carried ───────────────────────────────────────
create unique index branch_users_username_key on public.branch_users (username);
create unique index cash_counters_one_open_idx on public.cash_counters ((true)) where status = 'open';
create index cash_counters_opened_idx on public.cash_counters (opened_at desc);
create index orders_paid_at_idx on public.orders (paid_at);
create index order_feedback_created_idx on public.order_feedback (created_at desc);

-- ── New policies: any signed-in staff member ──────────────────────────────
do $$ declare t text; begin
  foreach t in array array[
    'branch_cash','branch_tax_settings','branch_tax_slabs','cash_transactions','categories','customers',
    'deal_items','deal_sizes','deals','delivery_orders','menu_item_ingredients','menu_item_sizes',
    'menu_items','order_items','orders','receipt_settings','riders','stock_items',
    'supplier_transactions','suppliers']
  loop
    execute format('create policy staff_access on public.%I for all to authenticated using (public.is_pos_staff()) with check (public.is_pos_staff())', t);
  end loop;
end $$;

create policy branch_users_select on public.branch_users for select to authenticated using (public.is_pos_staff());
create policy branch_users_update on public.branch_users for update to authenticated
  using (public.my_branch_role() in ('admin', 'manager') or public.my_company_id() is not null)
  with check ((public.my_branch_role() in ('admin', 'manager') or public.my_company_id() is not null)
              and (role <> 'admin'::branch_user_role or public.my_branch_role() = 'admin' or public.my_company_id() is not null));
create policy staff_read on public.cash_counters for select to authenticated using (public.is_pos_staff());
create policy staff_read on public.cash_counter_entries for select to authenticated using (public.is_pos_staff());
create policy staff_feedback_read on public.order_feedback for select to authenticated using (public.is_pos_staff());
create policy staff_feedback_delete on public.order_feedback for delete to authenticated using (public.is_pos_staff());
create policy website_feedback_read on public.order_feedback for select to anon, authenticated using (true);
create policy website_menu_read on public.categories for select to anon, authenticated using (true);
create policy website_menu_read on public.menu_items for select to anon, authenticated using (is_available);
create policy website_menu_read on public.menu_item_sizes for select to anon, authenticated
  using (exists (select 1 from public.menu_items m where m.id = menu_item_sizes.menu_item_id and m.is_available));

-- ── Functions ─────────────────────────────────────────────────────────────
drop function public.can_access_branch_text(text);

create or replace function public._app_user_json(u app_users) returns jsonb
language sql stable set search_path = '' as $$
  select jsonb_build_object(
    'id', u.id, 'branch_id', (select b.id from public.branches b order by b.created_at limit 1),
    'name', u.name, 'username', u.username,
    'email', '', 'phone', null, 'role', u.role, 'status', u.status, 'avatar_url', null,
    'created_at', u.created_at, 'updated_at', u.updated_at);
$$;

drop function public.app_list_users(uuid);
create function public.app_list_users() returns setof jsonb
language sql security definer set search_path = 'public' as $$
  select public._app_user_json(u) from public.app_users u order by u.created_at;
$$;

drop function public.app_save_user(uuid, uuid, text, text, text, text, text);
create function public.app_save_user(p_id uuid, p_name text, p_username text, p_password text, p_role text, p_status text)
returns jsonb language plpgsql security definer set search_path = 'public', 'extensions' as $$
declare u public.app_users;
begin
  if p_id is null then
    if coalesce(p_password, '') = '' then raise exception 'Password is required'; end if;
    insert into public.app_users (name, username, password_hash, role, status)
    values (p_name, trim(p_username), crypt(p_password, gen_salt('bf')),
            p_role::public.branch_user_role, p_status::public.branch_user_status)
    returning * into u;
  else
    update public.app_users set
      name = p_name, username = trim(p_username),
      password_hash = case when coalesce(p_password, '') = '' then password_hash
                           else crypt(p_password, gen_salt('bf')) end,
      role = p_role::public.branch_user_role, status = p_status::public.branch_user_status,
      updated_at = now()
    where id = p_id returning * into u;
  end if;
  return public._app_user_json(u);
exception when unique_violation then
  raise exception 'That username is already taken';
end $$;

create or replace function public.add_cash_counter_entry(p_counter_id uuid, p_kind text, p_amount numeric, p_reason text)
returns void language plpgsql security definer set search_path = '' as $$
declare c public.cash_counters;
begin
  select * into c from public.cash_counters where id = p_counter_id;
  if not found or not public.is_pos_staff() then
    raise exception 'Cash counter not found';
  end if;
  if c.status <> 'open' then
    raise exception 'This cash counter is already closed';
  end if;
  if p_kind not in ('in', 'out') then
    raise exception 'Invalid entry type';
  end if;
  if p_amount is null or p_amount <= 0 then
    raise exception 'Amount must be more than 0';
  end if;
  insert into public.cash_counter_entries (counter_id, kind, amount, reason, created_by, created_by_name)
  values (c.id, p_kind, round(p_amount, 2), trim(coalesce(p_reason, '')), auth.uid(), public.current_staff_name());
end;
$$;

create or replace function public.cash_counter_summary(p_counter_id uuid)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  c        public.cash_counters;
  v_end    timestamptz;
  v_sales  record;
  v_unpaid record;
  v_in     numeric;
  v_out    numeric;
begin
  select * into c from public.cash_counters where id = p_counter_id;
  if not found or not public.is_pos_staff() then
    raise exception 'Cash counter not found';
  end if;
  v_end := coalesce(c.closed_at, now());

  select
    coalesce(sum(o.total) filter (where o.payment_method = 'Cash'), 0) as cash,
    coalesce(sum(o.total) filter (where o.payment_method = 'Card'), 0) as card,
    coalesce(sum(o.total) filter (where o.payment_method not in ('Cash', 'Card')), 0) as online,
    coalesce(sum(o.total), 0) as total,
    count(*) as orders,
    coalesce(sum(o.discount_amt), 0) as discount,
    coalesce(sum(o.tax_amt), 0) as tax
  into v_sales
  from public.orders o
  where o.payment_status = 'Paid'
    and lower(o.status) <> 'cancelled'
    and o.paid_at >= c.opened_at and o.paid_at < v_end;

  select count(*) as n, coalesce(sum(o.total), 0) as amount
  into v_unpaid
  from public.orders o
  where o.payment_status <> 'Paid'
    and lower(o.status) <> 'cancelled'
    and o.created_at >= c.opened_at and o.created_at < v_end;

  select coalesce(sum(amount) filter (where kind = 'in'), 0),
         coalesce(sum(amount) filter (where kind = 'out'), 0)
  into v_in, v_out
  from public.cash_counter_entries where counter_id = c.id;

  return jsonb_build_object(
    'cash_sales',     v_sales.cash,
    'card_sales',     v_sales.card,
    'online_sales',   v_sales.online,
    'total_sales',    v_sales.total,
    'order_count',    v_sales.orders,
    'discount_total', v_sales.discount,
    'tax_total',      v_sales.tax,
    'unpaid_count',   v_unpaid.n,
    'unpaid_amount',  v_unpaid.amount,
    'cash_in',        v_in,
    'cash_out',       v_out,
    'expected_cash',  c.opening_cash + v_sales.cash + v_in - v_out
  );
end;
$$;

create or replace function public.close_cash_counter(p_counter_id uuid, p_counted_cash numeric, p_notes text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  c public.cash_counters;
  s jsonb;
begin
  select * into c from public.cash_counters where id = p_counter_id for update;
  if not found or not public.is_pos_staff() then
    raise exception 'Cash counter not found';
  end if;
  if c.status <> 'open' then
    raise exception 'This cash counter is already closed';
  end if;
  if p_counted_cash is null or p_counted_cash < 0 then
    raise exception 'Counted cash must be 0 or more';
  end if;

  update public.cash_counters set closed_at = now() where id = c.id;
  s := public.cash_counter_summary(c.id);

  update public.cash_counters set
    status         = 'closed',
    closed_by      = auth.uid(),
    closed_by_name = public.current_staff_name(),
    cash_sales     = (s->>'cash_sales')::numeric,
    card_sales     = (s->>'card_sales')::numeric,
    online_sales   = (s->>'online_sales')::numeric,
    total_sales    = (s->>'total_sales')::numeric,
    order_count    = (s->>'order_count')::int,
    discount_total = (s->>'discount_total')::numeric,
    cash_in        = (s->>'cash_in')::numeric,
    cash_out       = (s->>'cash_out')::numeric,
    expected_cash  = (s->>'expected_cash')::numeric,
    counted_cash   = round(p_counted_cash, 2),
    difference     = round(p_counted_cash, 2) - (s->>'expected_cash')::numeric,
    notes          = trim(coalesce(p_notes, ''))
  where id = c.id;
end;
$$;

drop function public.open_cash_counter(uuid, numeric);
create function public.open_cash_counter(p_opening_cash numeric)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
  if not public.is_pos_staff() then
    raise exception 'Not allowed' using errcode = '42501';
  end if;
  if p_opening_cash is null or p_opening_cash < 0 then
    raise exception 'Opening cash must be 0 or more';
  end if;
  insert into public.cash_counters (opened_by, opened_by_name, opening_cash)
  values (auth.uid(), public.current_staff_name(), round(p_opening_cash, 2))
  returning id into v_id;
  return v_id;
exception when unique_violation then
  raise exception 'A cash counter is already open';
end;
$$;

drop function public.dashboard_stats(uuid, timestamptz, timestamptz, integer);
create function public.dashboard_stats(p_from timestamptz, p_to timestamptz, p_utc_offset_min integer default 0)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
  v_off    interval := make_interval(mins => p_utc_offset_min);
  v_span   interval := p_to - p_from;
  v_hourly boolean  := (p_to - p_from) <= interval '36 hours';
  v_unit   text;
  v_step   interval;
  v_cur    jsonb;
  v_prev   jsonb;
  v_result jsonb;
begin
  if not public.is_pos_staff() then
    raise exception 'Not allowed' using errcode = '42501';
  end if;
  v_unit := case when v_hourly then 'hour' else 'day' end;
  v_step := case when v_hourly then interval '1 hour' else interval '1 day' end;

  select jsonb_build_object(
    'revenue',     coalesce(sum(o.total), 0),
    'paid_orders', count(*),
    'avg_order',   coalesce(round(avg(o.total), 2), 0),
    'discounts',   coalesce(sum(o.discount_amt), 0)
  ) into v_cur
  from public.orders o
  where o.payment_status = 'Paid' and lower(o.status) <> 'cancelled'
    and o.paid_at >= p_from and o.paid_at < p_to;

  select jsonb_build_object(
    'revenue',     coalesce(sum(o.total), 0),
    'paid_orders', count(*),
    'avg_order',   coalesce(round(avg(o.total), 2), 0)
  ) into v_prev
  from public.orders o
  where o.payment_status = 'Paid' and lower(o.status) <> 'cancelled'
    and o.paid_at >= p_from - v_span and o.paid_at < p_from;

  with paid as (
    select o.* from public.orders o
    where o.payment_status = 'Paid' and lower(o.status) <> 'cancelled'
      and o.paid_at >= p_from and o.paid_at < p_to
  ),
  paid_prev as (
    select o.* from public.orders o
    where o.payment_status = 'Paid' and lower(o.status) <> 'cancelled'
      and o.paid_at >= p_from - v_span and o.paid_at < p_from
  ),
  placed as (
    select o.* from public.orders o
    where o.created_at >= p_from and o.created_at < p_to
  ),
  buckets as (
    select generate_series(
      date_trunc(v_unit, p_from + v_off),
      date_trunc(v_unit, p_to - interval '1 second' + v_off),
      v_step) as b
  ),
  trend as (
    select b.b,
      coalesce((select sum(p.total) from paid p where date_trunc(v_unit, p.paid_at + v_off) = b.b), 0) as cur,
      coalesce((select sum(p.total) from paid_prev p where date_trunc(v_unit, p.paid_at + v_span + v_off) = b.b), 0) as prev
    from buckets b
  ),
  items as (
    select coalesce(mi.name, oi.item_name) as name, sum(oi.qty) as qty, sum(oi.total_price) as revenue
    from public.order_items oi
    join paid p on p.id = oi.order_id
    left join public.menu_items mi on mi.id = oi.menu_item_id
    group by 1
  ),
  custs as (
    select c.name, c.phone, count(*) as orders, sum(p.total) as spent
    from paid p join public.customers c on c.id = p.customer_id
    group by c.id, c.name, c.phone
  )
  select jsonb_build_object(
    'current',  v_cur || jsonb_build_object(
                  'items_sold', coalesce((select sum(qty) from items), 0),
                  'orders_placed', (select count(*) from placed where lower(status) <> 'cancelled'),
                  'cancelled', (select count(*) from placed where lower(status) = 'cancelled'),
                  'unpaid_amount', coalesce((select sum(total) from placed
                                             where lower(status) <> 'cancelled' and payment_status <> 'Paid'), 0)),
    'previous', v_prev,
    'bucket',   v_unit,
    'trend',    coalesce((select jsonb_agg(jsonb_build_object('t', t.b, 'cur', t.cur, 'prev', t.prev) order by t.b) from trend t), '[]'::jsonb),
    'hours',    (select jsonb_agg(jsonb_build_object('h', h, 'revenue', coalesce(x.revenue, 0), 'orders', coalesce(x.n, 0)) order by h)
                 from generate_series(0, 23) h
                 left join (select extract(hour from p.paid_at + v_off)::int as hr, sum(p.total) as revenue, count(*) as n
                            from paid p group by 1) x on x.hr = h),
    'by_method', jsonb_build_object(
                  'cash',   coalesce((select sum(total) from paid where payment_method = 'Cash'), 0),
                  'card',   coalesce((select sum(total) from paid where payment_method = 'Card'), 0),
                  'online', coalesce((select sum(total) from paid where payment_method not in ('Cash', 'Card')), 0)),
    'by_type',  coalesce((select jsonb_agg(jsonb_build_object('type', order_type, 'orders', n, 'revenue', revenue) order by revenue desc)
                          from (select order_type, count(*) as n, sum(total) as revenue from paid group by order_type) t), '[]'::jsonb),
    'channel',  jsonb_build_object(
                  'website_orders',  (select count(*) from paid where customer_type = 'Online'),
                  'website_revenue', coalesce((select sum(total) from paid where customer_type = 'Online'), 0),
                  'pos_orders',      (select count(*) from paid where customer_type is distinct from 'Online'),
                  'pos_revenue',     coalesce((select sum(total) from paid where customer_type is distinct from 'Online'), 0)),
    'top_items',     coalesce((select jsonb_agg(to_jsonb(i) order by i.revenue desc)
                               from (select * from items order by revenue desc limit 6) i), '[]'::jsonb),
    'top_customers', coalesce((select jsonb_agg(to_jsonb(c) order by c.spent desc)
                               from (select * from custs order by spent desc limit 5) c), '[]'::jsonb)
  ) into v_result;

  v_result := v_result || jsonb_build_object(
    'live', jsonb_build_object(
      'pending_orders', (select count(*) from public.orders where lower(status) = 'pending'),
      'active_deliveries', (select count(*) from public.delivery_orders
                            where status in ('pending', 'assigned', 'on_the_way')),
      'counter', (select jsonb_build_object('opened_at', c.opened_at, 'opened_by', c.opened_by_name,
                                            'expected_cash', (public.cash_counter_summary(c.id)->>'expected_cash')::numeric)
                  from public.cash_counters c where c.status = 'open'),
      'recent', coalesce((select jsonb_agg(to_jsonb(r) order by r.created_at desc) from (
                   select order_number, customer_name, customer_type, order_type, total, status, payment_status, created_at
                   from public.orders
                   order by created_at desc limit 8) r), '[]'::jsonb)
    ));

  return v_result;
end;
$$;

create or replace function public.insert_website_order(p_uid uuid, p_delivery boolean, p_customer_name text, p_customer_phone text, p_address text, p_notes text, p_lines jsonb, p_paid_by_card boolean, p_delivery_fee numeric)
returns text language plpgsql security definer set search_path = '' as $$
declare
  v_fee      numeric := case when p_delivery then greatest(coalesce(p_delivery_fee, 0), 0) else 0 end;
  v_number   text;
  v_order_id uuid;
  v_subtotal numeric;
  v_summary  text;
begin
  select coalesce(sum((l->>'total_price')::numeric), 0) into v_subtotal
  from jsonb_array_elements(p_lines) l;

  perform pg_advisory_xact_lock(hashtext('order_number'));
  select '#' || (coalesce(max(nullif(regexp_replace(order_number, '\D', '', 'g'), '')::int), 1000) + 1)
    into v_number
  from public.orders;

  insert into public.orders (
    order_number, order_type, customer_type, customer_name, customer_phone,
    table_number, status, payment_method, payment_status,
    subtotal, discount_pct, discount_flat, discount_amt, tax_pct, tax_amt, delivery_fee, total, notes,
    customer_user_id
  ) values (
    v_number, case when p_delivery then 'Delivery' else 'Takeaway' end, 'Online',
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

  insert into public.order_items (order_id, menu_item_id, item_name, item_emoji, size, unit_price, qty, total_price)
  select v_order_id, (l->>'menu_item_id')::uuid, l->>'item_name', '', l->>'size',
         (l->>'unit_price')::numeric, (l->>'qty')::int, (l->>'total_price')::numeric
  from jsonb_array_elements(p_lines) l;

  if p_delivery then
    select string_agg((l->>'item_name') || ' × ' || (l->>'qty'), ', ') into v_summary
    from jsonb_array_elements(p_lines) l;

    insert into public.delivery_orders (order_id, order_num, customer_name, phone, address, items, amount, notes, status)
    values (v_order_id, v_number, trim(p_customer_name), trim(p_customer_phone), trim(p_address),
            v_summary, v_subtotal + v_fee,
            concat_ws(' • ',
              case when p_paid_by_card then 'PAID ONLINE - do not collect cash' end,
              nullif(trim(p_notes), '')),
            'pending');
  end if;

  return v_number;
end;
$$;

create or replace function public.link_order_customer() returns trigger
language plpgsql security definer set search_path = '' as $$
declare
  v_digits text := regexp_replace(coalesce(new.customer_phone, ''), '\D', '', 'g');
begin
  if new.customer_id is null and length(v_digits) >= 7 then
    select c.id into new.customer_id
    from public.customers c
    where regexp_replace(coalesce(c.phone, ''), '\D', '', 'g') = v_digits
    order by c.created_at
    limit 1;

    if new.customer_id is null and new.customer_type = 'Online' then
      insert into public.customers (name, phone, type, orders, spent, balance, loyalty, discount)
      values (coalesce(nullif(trim(new.customer_name), ''), 'Website customer'),
              trim(new.customer_phone), 'online', 0, 0, 0, 'regular', 0)
      returning id into new.customer_id;
    end if;
  end if;
  return new;
end;
$$;

create or replace function public.place_table_order(p_token text, p_customer_name text, p_notes text, p_items jsonb)
returns text language plpgsql security definer set search_path = '' as $$
declare
  v_table    text;
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
  select t.table_number into v_table from public.tables t
  where t.table_number = p_token and t.deleted_at is null;
  if v_table is null then
    raise exception 'This table QR code is not valid. Please ask the staff for help.';
  end if;
  if jsonb_typeof(p_items) <> 'array' or jsonb_array_length(p_items) = 0 then
    raise exception 'Your cart is empty';
  end if;
  if (select count(*) from public.orders
      where table_number = v_table and created_at > now() - interval '10 minutes') >= 5 then
    raise exception 'Too many orders from this table. Please ask the staff for help.';
  end if;

  for v_item in select * from jsonb_array_elements(p_items) loop
    v_qty  := (v_item->>'qty')::int;
    v_size := coalesce(v_item->>'size', '');
    if v_qty is null or v_qty < 1 or v_qty > 99 then
      raise exception 'Invalid quantity';
    end if;

    select id, name, price into v_menu from public.menu_items
    where id = (v_item->>'menu_item_id')::uuid and is_available;
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

  perform pg_advisory_xact_lock(hashtext('order_number'));
  select '#' || (coalesce(max(nullif(regexp_replace(order_number, '\D', '', 'g'), '')::int), 1000) + 1)
    into v_number
  from public.orders;

  insert into public.orders (
    order_number, order_type, customer_type, customer_name, customer_phone,
    table_number, status, payment_method, payment_status,
    subtotal, discount_pct, discount_flat, discount_amt, tax_pct, tax_amt, total, notes,
    customer_user_id
  ) values (
    v_number, 'Dine-in', 'Online',
    coalesce(nullif(trim(p_customer_name), ''), 'Table ' || v_table), '',
    v_table, 'pending', 'Cash', 'Unpaid',
    v_subtotal, 0, 0, 0, 0, 0, v_subtotal,
    concat_ws(' • ', 'Table QR order', nullif(trim(p_notes), '')),
    auth.uid()
  ) returning id into v_order_id;

  insert into public.order_items (order_id, menu_item_id, item_name, item_emoji, size, unit_price, qty, total_price)
  select v_order_id, (l->>'menu_item_id')::uuid, l->>'item_name', '', l->>'size',
         (l->>'unit_price')::numeric, (l->>'qty')::int, (l->>'total_price')::numeric
  from jsonb_array_elements(v_lines) l;

  return v_number;
end;
$$;

create or replace function public.price_website_items(p_items jsonb)
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare
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
    where id = (v_item->>'menu_item_id')::uuid and is_available;
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

create or replace function public.rider_mark_delivered(p_delivery_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_rider public.riders%rowtype;
  v_order public.delivery_orders%rowtype;
begin
  select * into v_rider from public.riders where id = public.my_rider_id();
  if v_rider.id is null then raise exception 'Not a rider account'; end if;

  update public.delivery_orders
  set status = 'delivered', delivered_at = now()
  where id = p_delivery_id
    and rider_id = v_rider.id
    and status in ('assigned', 'on_the_way')
  returning * into v_order;
  if v_order.id is null then raise exception 'This delivery is not assigned to you or is already closed'; end if;

  update public.riders
  set total_deliveries = total_deliveries + 1,
      total_earnings   = total_earnings + v_rider.charge_per_delivery,
      status           = 'available'
  where id = v_rider.id;

  if v_rider.charge_per_delivery > 0 then
    insert into public.cash_transactions (type, amount, direction, ref_label, note)
    values ('expense_out', v_rider.charge_per_delivery, 'out', v_order.order_num,
            'Delivery charge — ' || v_order.order_num || ' (Rider)');

    update public.branch_cash
    set balance = balance - v_rider.charge_per_delivery, updated_at = now();
  end if;
end;
$$;

create or replace function public.start_card_checkout(p_delivery boolean, p_customer_name text, p_customer_phone text, p_address text, p_notes text, p_items jsonb)
returns jsonb language plpgsql security definer set search_path = '' as $$
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
  if v_amount < 0.30 then
    raise exception 'Online payment needs an order of at least £0.30';
  end if;

  insert into public.website_payments (
    customer_user_id, delivery, customer_name, customer_phone, address, notes, lines, delivery_fee, amount
  ) values (
    v_uid, p_delivery, trim(p_customer_name), trim(p_customer_phone),
    case when p_delivery then trim(p_address) else '' end, coalesce(trim(p_notes), ''), v_lines, v_fee, v_amount
  ) returning id into v_id;

  return jsonb_build_object('payment_id', v_id, 'amount', v_amount, 'delivery_fee', v_fee, 'lines', v_lines);
end;
$$;

create or replace function public.submit_order_feedback(p_order_id uuid, p_rating integer, p_comment text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_uid   uuid := auth.uid();
  v_order record;
  v_parts text[];
  v_name  text;
begin
  if v_uid is null then
    raise exception 'Please log in to leave feedback' using errcode = '42501';
  end if;
  if p_rating is null or p_rating < 1 or p_rating > 5 then
    raise exception 'Please choose a rating from 1 to 5 stars';
  end if;
  if char_length(coalesce(p_comment, '')) > 500 then
    raise exception 'Feedback can be at most 500 characters';
  end if;

  select id, status, customer_name into v_order
  from public.orders
  where id = p_order_id and customer_user_id = v_uid;
  if not found then
    raise exception 'Order not found';
  end if;
  if lower(v_order.status) not in ('completed', 'delivered', 'served') then
    raise exception 'You can leave feedback once your order is completed';
  end if;
  if exists (select 1 from public.order_feedback where order_id = p_order_id) then
    raise exception 'You have already left feedback for this order';
  end if;

  v_parts := regexp_split_to_array(trim(coalesce(v_order.customer_name, '')), '\s+');
  v_name  := coalesce(nullif(v_parts[1], ''), 'Customer');
  if array_length(v_parts, 1) > 1 then
    v_name := v_name || ' ' || upper(left(v_parts[array_length(v_parts, 1)], 1)) || '.';
  end if;

  insert into public.order_feedback (order_id, customer_user_id, display_name, rating, comment)
  values (p_order_id, v_uid, v_name, p_rating, trim(coalesce(p_comment, '')));
end;
$$;

drop function public.update_branch_cash(text, numeric, text, bigint, text, text);
create function public.update_branch_cash(p_amount numeric, p_type text, p_ref_id bigint default null, p_ref_label text default null, p_note text default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_pos_staff() then
    raise exception 'Not allowed' using errcode = '42501';
  end if;

  update public.branch_cash set balance = balance + p_amount, updated_at = now();
  if not found then
    insert into public.branch_cash (balance, updated_at) values (p_amount, now());
  end if;

  insert into public.cash_transactions (type, ref_id, ref_label, amount, direction, note)
  values (p_type, p_ref_id, p_ref_label, abs(p_amount),
          case when p_amount >= 0 then 'in' else 'out' end, p_note);
end;
$$;

revoke all on function public.app_list_users() from public;
revoke all on function public.app_save_user(uuid, text, text, text, text, text) from public;
revoke all on function public.open_cash_counter(numeric) from public;
revoke all on function public.dashboard_stats(timestamptz, timestamptz, integer) from public;
revoke all on function public.update_branch_cash(numeric, text, bigint, text, text) from public;
grant execute on function public.app_list_users() to authenticated;
grant execute on function public.app_save_user(uuid, text, text, text, text, text) to authenticated;
grant execute on function public.open_cash_counter(numeric) to authenticated;
grant execute on function public.dashboard_stats(timestamptz, timestamptz, integer) to authenticated;
grant execute on function public.update_branch_cash(numeric, text, bigint, text, text) to authenticated;
