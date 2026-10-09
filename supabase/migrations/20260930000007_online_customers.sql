-- Website customers appear in the POS Customers list.
-- A website order (customer_type 'Online') whose phone doesn't match a saved
-- customer creates one (type 'online'); later orders link to it by phone.

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

    -- First website order from this phone: save them as an online customer.
    if new.customer_id is null and new.customer_type = 'Online' then
      insert into public.customers (branch_id, name, phone, type, orders, spent, balance, loyalty, discount)
      values (new.branch_id, coalesce(nullif(trim(new.customer_name), ''), 'Website customer'),
              trim(new.customer_phone), 'online', 0, 0, 0, 'regular', 0)
      returning id into new.customer_id;
    end if;
  end if;
  return new;
end;
$$;

-- Backfill: past website orders with no customer. One customer per branch +
-- phone, named after their most recent order.
do $$
declare
  r record;
  v_id uuid;
begin
  for r in
    select distinct on (o.branch_id, regexp_replace(o.customer_phone, '\D', '', 'g'))
           o.branch_id, o.customer_name, o.customer_phone,
           regexp_replace(o.customer_phone, '\D', '', 'g') as digits
    from public.orders o
    where o.customer_id is null
      and o.customer_type = 'Online'
      and length(regexp_replace(coalesce(o.customer_phone, ''), '\D', '', 'g')) >= 7
    order by o.branch_id, regexp_replace(o.customer_phone, '\D', '', 'g'), o.created_at desc
  loop
    insert into public.customers (branch_id, name, phone, type, orders, spent, balance, loyalty, discount)
    values (r.branch_id, coalesce(nullif(trim(r.customer_name), ''), 'Website customer'),
            trim(r.customer_phone), 'online', 0, 0, 0, 'regular', 0)
    returning id into v_id;

    -- Linking fires the stats trigger, which fills orders/spent.
    update public.orders o
    set customer_id = v_id
    where o.customer_id is null
      and o.branch_id = r.branch_id
      and regexp_replace(coalesce(o.customer_phone, ''), '\D', '', 'g') = r.digits;
  end loop;
end $$;
