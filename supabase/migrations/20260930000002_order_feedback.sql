-- Step 6: customer feedback on the website.
--   * a signed-in customer can rate each of their own completed orders once
--     (1–5 stars + optional comment) through submit_order_feedback()
--   * everyone can read the website branch's feedback (shown on the home page)
--   * POS staff of the branch can read and delete feedback (moderation)

create table if not exists public.order_feedback (
  id               uuid primary key default gen_random_uuid(),
  order_id         uuid not null unique references public.orders(id) on delete cascade,
  branch_id        uuid not null,
  customer_user_id uuid references auth.users(id) on delete set null,
  display_name     text not null,  -- "Shahab M." — never the full name or phone
  rating           smallint not null check (rating between 1 and 5),
  comment          text not null default '' check (char_length(comment) <= 500),
  created_at       timestamptz not null default now()
);
create index if not exists order_feedback_branch_created_idx
  on public.order_feedback (branch_id, created_at desc);

alter table public.order_feedback enable row level security;

drop policy if exists website_feedback_read on public.order_feedback;
create policy website_feedback_read on public.order_feedback for select to anon, authenticated
  using (branch_id = public.website_branch_id());

drop policy if exists staff_feedback_read on public.order_feedback;
create policy staff_feedback_read on public.order_feedback for select to authenticated
  using (branch_id = public.my_branch_id());

drop policy if exists staff_feedback_delete on public.order_feedback;
create policy staff_feedback_delete on public.order_feedback for delete to authenticated
  using (branch_id = public.my_branch_id());

-- No insert/update policies: customers write only through this function.
create or replace function public.submit_order_feedback(
  p_order_id uuid,
  p_rating int,
  p_comment text
) returns void
language plpgsql security definer set search_path = '' as $$
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

  select id, branch_id, status, customer_name into v_order
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

  -- Public name: first name + last initial.
  v_parts := regexp_split_to_array(trim(coalesce(v_order.customer_name, '')), '\s+');
  v_name  := coalesce(nullif(v_parts[1], ''), 'Customer');
  if array_length(v_parts, 1) > 1 then
    v_name := v_name || ' ' || upper(left(v_parts[array_length(v_parts, 1)], 1)) || '.';
  end if;

  insert into public.order_feedback (order_id, branch_id, customer_user_id, display_name, rating, comment)
  values (p_order_id, v_order.branch_id, v_uid, v_name, p_rating, trim(coalesce(p_comment, '')));
end;
$$;

revoke all on function public.submit_order_feedback(uuid, int, text) from public, anon;
grant execute on function public.submit_order_feedback(uuid, int, text) to authenticated;
