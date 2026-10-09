-- When a delivery is marked delivered (the rider has handed over the money),
-- its order becomes completed + paid, so the invoice on the Orders screen, the
-- customer's "My Orders" and the Cash Counter all update.

create or replace function public.settle_order_on_delivery()
returns trigger language plpgsql security definer set search_path = '' as $$
begin
  if new.status = 'delivered' and old.status is distinct from 'delivered' and new.order_id is not null then
    update public.orders o
    set status         = 'completed',
        payment_status = 'Paid',
        -- Already paid (e.g. card/online) keeps its time; otherwise paid on delivery.
        paid_at        = case when o.payment_status = 'Paid' then o.paid_at
                              else coalesce(new.delivered_at, now()) end
    where o.id = new.order_id
      and lower(o.status) <> 'cancelled';
  end if;
  return null;
end;
$$;

drop trigger if exists delivery_orders_settle_order on public.delivery_orders;
create trigger delivery_orders_settle_order
  after update of status on public.delivery_orders
  for each row execute function public.settle_order_on_delivery();

-- Backfill deliveries that were already marked delivered.
update public.orders o
set status         = 'completed',
    payment_status = 'Paid',
    paid_at        = case when o.payment_status = 'Paid' then o.paid_at
                          else coalesce(d.delivered_at, o.created_at) end
from public.delivery_orders d
where d.order_id = o.id
  and d.status = 'delivered'
  and lower(o.status) <> 'cancelled'
  and (o.payment_status <> 'Paid' or o.status <> 'completed');
