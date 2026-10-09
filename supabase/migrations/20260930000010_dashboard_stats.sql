-- Sales dashboard for the desktop POS: one call returns every figure for a
-- period, so the numbers agree with each other and with the Cash Counter.
--   * Sales = orders marked Paid (not cancelled), counted when they were paid.
--   * p_utc_offset_min is the device's UTC offset, so hours/days are local.

create or replace function public.dashboard_stats(
  p_branch_id uuid,
  p_from timestamptz,
  p_to timestamptz,
  p_utc_offset_min int default 0
) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
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
  if not public.can_access_branch(p_branch_id) then
    raise exception 'Not allowed for this branch' using errcode = '42501';
  end if;
  v_unit := case when v_hourly then 'hour' else 'day' end;
  v_step := case when v_hourly then interval '1 hour' else interval '1 day' end;

  -- Headline figures for a window.
  select jsonb_build_object(
    'revenue',     coalesce(sum(o.total), 0),
    'paid_orders', count(*),
    'avg_order',   coalesce(round(avg(o.total), 2), 0),
    'discounts',   coalesce(sum(o.discount_amt), 0)
  ) into v_cur
  from public.orders o
  where o.branch_id = p_branch_id and o.payment_status = 'Paid' and lower(o.status) <> 'cancelled'
    and o.paid_at >= p_from and o.paid_at < p_to;

  select jsonb_build_object(
    'revenue',     coalesce(sum(o.total), 0),
    'paid_orders', count(*),
    'avg_order',   coalesce(round(avg(o.total), 2), 0)
  ) into v_prev
  from public.orders o
  where o.branch_id = p_branch_id and o.payment_status = 'Paid' and lower(o.status) <> 'cancelled'
    and o.paid_at >= p_from - v_span and o.paid_at < p_from;

  with paid as (
    select o.* from public.orders o
    where o.branch_id = p_branch_id and o.payment_status = 'Paid' and lower(o.status) <> 'cancelled'
      and o.paid_at >= p_from and o.paid_at < p_to
  ),
  paid_prev as (
    select o.* from public.orders o
    where o.branch_id = p_branch_id and o.payment_status = 'Paid' and lower(o.status) <> 'cancelled'
      and o.paid_at >= p_from - v_span and o.paid_at < p_from
  ),
  placed as (
    select o.* from public.orders o
    where o.branch_id = p_branch_id and o.created_at >= p_from and o.created_at < p_to
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

  -- Live status (not tied to the period).
  v_result := v_result || jsonb_build_object(
    'live', jsonb_build_object(
      'pending_orders', (select count(*) from public.orders
                         where branch_id = p_branch_id and lower(status) = 'pending'),
      'active_deliveries', (select count(*) from public.delivery_orders
                            where branch_id = p_branch_id and status in ('pending', 'assigned', 'on_the_way')),
      'counter', (select jsonb_build_object('opened_at', c.opened_at, 'opened_by', c.opened_by_name,
                                            'expected_cash', (public.cash_counter_summary(c.id)->>'expected_cash')::numeric)
                  from public.cash_counters c where c.branch_id = p_branch_id and c.status = 'open'),
      'recent', coalesce((select jsonb_agg(to_jsonb(r) order by r.created_at desc) from (
                   select order_number, customer_name, customer_type, order_type, total, status, payment_status, created_at
                   from public.orders where branch_id = p_branch_id
                   order by created_at desc limit 8) r), '[]'::jsonb)
    ));

  return v_result;
end;
$$;

revoke all on function public.dashboard_stats(uuid, timestamptz, timestamptz, int) from public, anon;
grant execute on function public.dashboard_stats(uuid, timestamptz, timestamptz, int) to authenticated;
