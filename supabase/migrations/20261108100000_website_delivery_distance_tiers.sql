-- Website delivery charge by distance from the restaurant:
--   up to 3 miles = £5, up to 5 miles = £8, up to 7 miles = £10, further = no delivery.
--   * branches.delivery_postcode is the restaurant's postcode (the starting point)
--   * the website works out the customer's distance and sends it; the amount is
--     decided here, so the website never chooses the price
--   * takeaway and table orders have no delivery charge

alter table public.branches add column if not exists delivery_postcode text not null default '';

create or replace function public.website_delivery_origin()
returns text language sql stable security definer set search_path = '' as $$
  select coalesce((select b.delivery_postcode from public.branches b where b.id = public.website_branch_id()), '')
$$;
revoke all on function public.website_delivery_origin() from public;
grant execute on function public.website_delivery_origin() to anon, authenticated;

create or replace function public.website_delivery_fee_for(p_miles numeric)
returns numeric language plpgsql immutable set search_path = '' as $$
begin
  if p_miles is null or p_miles < 0 then
    raise exception 'Enter a valid delivery postcode';
  end if;
  if p_miles <= 3 then return 5; end if;
  if p_miles <= 5 then return 8; end if;
  if p_miles <= 7 then return 10; end if;
  raise exception 'Sorry, we only deliver within 7 miles';
end;
$$;
revoke all on function public.website_delivery_fee_for(numeric) from public;
grant execute on function public.website_delivery_fee_for(numeric) to anon, authenticated;

-- ── Cash on delivery ──────────────────────────────────────────────────────
drop function if exists public.place_website_order(boolean, text, text, text, text, jsonb);
create function public.place_website_order(
  p_delivery boolean,
  p_customer_name text,
  p_customer_phone text,
  p_address text,
  p_notes text,
  p_items jsonb,
  p_distance_miles numeric default null
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
    public.price_website_items(p_items), false,
    case when p_delivery then public.website_delivery_fee_for(p_distance_miles) else 0 end);
end;
$$;
revoke all on function public.place_website_order(boolean, text, text, text, text, jsonb, numeric) from public, anon;
grant execute on function public.place_website_order(boolean, text, text, text, text, jsonb, numeric) to authenticated;

-- ── Card payment, step 1 ──────────────────────────────────────────────────
drop function if exists public.start_card_checkout(boolean, text, text, text, text, jsonb);
create function public.start_card_checkout(
  p_delivery boolean,
  p_customer_name text,
  p_customer_phone text,
  p_address text,
  p_notes text,
  p_items jsonb,
  p_distance_miles numeric default null
) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare
  v_uid    uuid := auth.uid();
  v_lines  jsonb;
  v_fee    numeric := case when p_delivery then public.website_delivery_fee_for(p_distance_miles) else 0 end;
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
revoke all on function public.start_card_checkout(boolean, text, text, text, text, jsonb, numeric) from public, anon;
grant execute on function public.start_card_checkout(boolean, text, text, text, text, jsonb, numeric) to authenticated;
