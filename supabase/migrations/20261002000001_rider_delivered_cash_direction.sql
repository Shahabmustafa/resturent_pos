-- rider_mark_delivered: cash_transactions.direction is NOT NULL — record the rider charge as 'out'.
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
    insert into public.cash_transactions (branch_id, type, amount, direction, ref_label, note)
    values (v_order.branch_id::text, 'expense_out', v_rider.charge_per_delivery, 'out', v_order.order_num,
            'Delivery charge — ' || v_order.order_num || ' (Rider)');

    update public.branch_cash
    set balance = balance - v_rider.charge_per_delivery, updated_at = now()
    where branch_id = v_order.branch_id::text;
  end if;
end;
$$;
