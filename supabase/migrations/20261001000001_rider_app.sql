-- Rider mobile app: riders sign in with their phone number + a password the
-- branch admin sets in the POS (Delivery -> Riders). The auth account is made
-- by the manage-rider-login Edge Function with the email <phone digits>@rider.pos.
-- A rider can only read their own row and the deliveries assigned to them;
-- every change goes through the security-definer functions below.

alter table public.riders
  add column if not exists auth_user_id uuid unique references auth.users(id) on delete set null;

create or replace function public.my_rider_id()
returns uuid language sql stable security definer set search_path = '' as $$
  select r.id from public.riders r where r.auth_user_id = (select auth.uid()) limit 1
$$;

revoke all on function public.my_rider_id() from public, anon;
grant execute on function public.my_rider_id() to authenticated;

-- ── Read access ───────────────────────────────────────────────────────────
-- Dropped first so the file can be re-run safely.
drop policy if exists rider_self_select on public.riders;
drop policy if exists rider_orders_select on public.delivery_orders;

create policy rider_self_select on public.riders for select to authenticated
  using (auth_user_id = (select auth.uid()));

create policy rider_orders_select on public.delivery_orders for select to authenticated
  using (rider_id is not null and rider_id = public.my_rider_id());

-- ── Rider actions ─────────────────────────────────────────────────────────

-- Go online (available) or offline. A rider on a delivery stays busy.
create or replace function public.rider_set_online(p_online boolean)
returns text language plpgsql security definer set search_path = '' as $$
declare
  v_status text;
begin
  update public.riders
  set status = case when p_online then 'available' else 'offline' end
  where id = public.my_rider_id() and status <> 'busy'
  returning status into v_status;

  if v_status is null then
    select status into v_status from public.riders where id = public.my_rider_id();
  end if;
  if v_status is null then raise exception 'Not a rider account'; end if;
  return v_status;
end;
$$;

-- Picked up from the restaurant: assigned -> on the way.
create or replace function public.rider_start_trip(p_delivery_id uuid)
returns void language plpgsql security definer set search_path = '' as $$
begin
  update public.delivery_orders
  set status = 'on_the_way'
  where id = p_delivery_id
    and rider_id = public.my_rider_id()
    and status = 'assigned';
  if not found then raise exception 'This delivery is not assigned to you or has already started'; end if;
end;
$$;

-- Handed to the customer: same bookkeeping as "Mark Delivered" in the POS —
-- rider stats + free again, rider charge expensed from branch cash. The
-- delivery_orders_settle_order trigger then marks the invoice completed + paid.
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

revoke all on function public.rider_set_online(boolean), public.rider_start_trip(uuid),
  public.rider_mark_delivered(uuid) from public, anon;
grant execute on function public.rider_set_online(boolean), public.rider_start_trip(uuid),
  public.rider_mark_delivered(uuid) to authenticated;
