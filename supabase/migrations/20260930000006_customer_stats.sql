-- Regular customers: link orders to saved customers and keep their stats current.
--   * An order without customer_id is linked to the branch's saved customer with
--     the same phone number (digits only), for POS and website orders alike.
--   * customers.orders / customers.spent are recalculated from their orders
--     (cancelled orders excluded) whenever an order changes.

create or replace function public.link_order_customer()
returns trigger language plpgsql security definer set search_path = '' as $$
declare
  v_digits text := regexp_replace(coalesce(new.customer_phone, ''), '\D', '', 'g');
begin
  if new.customer_id is null and length(v_digits) >= 7 then
    select c.id into new.customer_id
    from public.customers c
    where c.branch_id = new.branch_id
      and regexp_replace(coalesce(c.phone, ''), '\D', '', 'g') = v_digits
    order by c.created_at
    limit 1;
  end if;
  return new;
end;
$$;

create or replace function public.refresh_customer_stats(p_customer_id uuid)
returns void language sql security definer set search_path = '' as $$
  update public.customers c
  set orders = s.cnt, spent = s.total
  from (
    select count(*)::int as cnt, coalesce(sum(o.total), 0) as total
    from public.orders o
    where o.customer_id = p_customer_id and lower(o.status) <> 'cancelled'
  ) s
  where c.id = p_customer_id
$$;
revoke all on function public.refresh_customer_stats(uuid) from public, anon, authenticated;

create or replace function public.orders_refresh_customer_stats()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if tg_op in ('INSERT', 'UPDATE') and new.customer_id is not null then
    perform public.refresh_customer_stats(new.customer_id);
  end if;
  if tg_op in ('UPDATE', 'DELETE') and old.customer_id is not null
     and (tg_op = 'DELETE' or old.customer_id is distinct from new.customer_id) then
    perform public.refresh_customer_stats(old.customer_id);
  end if;
  return null;
end;
$$;

drop trigger if exists orders_link_customer on public.orders;
create trigger orders_link_customer
  before insert on public.orders
  for each row execute function public.link_order_customer();

drop trigger if exists orders_customer_stats on public.orders;
create trigger orders_customer_stats
  after insert or delete or update of status, total, customer_id on public.orders
  for each row execute function public.orders_refresh_customer_stats();

-- Backfill: link past orders by phone, then recalculate every customer.
update public.orders o
set customer_id = c.id
from public.customers c
where o.customer_id is null
  and c.branch_id = o.branch_id
  and length(regexp_replace(coalesce(o.customer_phone, ''), '\D', '', 'g')) >= 7
  and regexp_replace(coalesce(c.phone, ''), '\D', '', 'g')
      = regexp_replace(coalesce(o.customer_phone, ''), '\D', '', 'g');

select public.refresh_customer_stats(id) from public.customers;
