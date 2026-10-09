-- Cash Counter (shift / till) for the desktop POS.
--   * A cashier opens the counter with the cash already in the drawer.
--   * While open, sales paid during the shift are totalled by payment method.
--   * Cash in / cash out entries record money added to or taken from the drawer.
--   * Closing stores a report: expected cash vs counted cash (short / over).
-- All writes go through the functions below; staff can only read their branch.

-- ── When an order was paid ──────────────────────────────────────────────────
alter table public.orders add column if not exists paid_at timestamptz;

create or replace function public.set_order_paid_at()
returns trigger language plpgsql set search_path = '' as $$
begin
  if new.payment_status = 'Paid' then
    if tg_op = 'INSERT' or old.payment_status is distinct from 'Paid' or new.paid_at is null then
      new.paid_at := coalesce(new.paid_at, now());
    end if;
  else
    new.paid_at := null;
  end if;
  return new;
end;
$$;

drop trigger if exists orders_set_paid_at on public.orders;
create trigger orders_set_paid_at
  before insert or update of payment_status on public.orders
  for each row execute function public.set_order_paid_at();

update public.orders set paid_at = created_at where payment_status = 'Paid' and paid_at is null;
create index if not exists orders_branch_paid_at_idx on public.orders (branch_id, paid_at);

-- ── Tables ──────────────────────────────────────────────────────────────────
create table if not exists public.cash_counters (
  id             uuid primary key default gen_random_uuid(),
  branch_id      uuid not null references public.branches(id) on delete cascade,
  status         text not null default 'open' check (status in ('open', 'closed')),
  opened_at      timestamptz not null default now(),
  opened_by      uuid references auth.users(id) on delete set null,
  opened_by_name text not null default '',
  opening_cash   numeric(12,2) not null default 0 check (opening_cash >= 0),
  closed_at      timestamptz,
  closed_by      uuid references auth.users(id) on delete set null,
  closed_by_name text,
  -- Closing report (filled when the counter is closed)
  cash_sales     numeric(12,2),
  card_sales     numeric(12,2),
  online_sales   numeric(12,2),
  total_sales    numeric(12,2),
  order_count    int,
  discount_total numeric(12,2),
  cash_in        numeric(12,2),
  cash_out       numeric(12,2),
  expected_cash  numeric(12,2),
  counted_cash   numeric(12,2),
  difference     numeric(12,2),
  notes          text not null default ''
);
-- Only one open counter per branch.
create unique index if not exists cash_counters_one_open_idx
  on public.cash_counters (branch_id) where status = 'open';
create index if not exists cash_counters_branch_opened_idx
  on public.cash_counters (branch_id, opened_at desc);

create table if not exists public.cash_counter_entries (
  id              uuid primary key default gen_random_uuid(),
  counter_id      uuid not null references public.cash_counters(id) on delete cascade,
  branch_id       uuid not null references public.branches(id) on delete cascade,
  kind            text not null check (kind in ('in', 'out')),
  amount          numeric(12,2) not null check (amount > 0),
  reason          text not null default '',
  created_by      uuid references auth.users(id) on delete set null,
  created_by_name text not null default '',
  created_at      timestamptz not null default now()
);
create index if not exists cash_counter_entries_counter_idx
  on public.cash_counter_entries (counter_id, created_at);

alter table public.cash_counters enable row level security;
alter table public.cash_counter_entries enable row level security;

drop policy if exists branch_read on public.cash_counters;
create policy branch_read on public.cash_counters for select to authenticated
  using (public.can_access_branch(branch_id));
drop policy if exists branch_read on public.cash_counter_entries;
create policy branch_read on public.cash_counter_entries for select to authenticated
  using (public.can_access_branch(branch_id));

-- ── Helpers ─────────────────────────────────────────────────────────────────
create or replace function public.current_staff_name()
returns text language sql stable security definer set search_path = '' as $$
  select coalesce(
    (select coalesce(nullif(bu.name, ''), bu.username)
     from public.branch_users bu where bu.auth_user_id = (select auth.uid()) limit 1),
    (select u.email from auth.users u where u.id = (select auth.uid())),
    'Staff')
$$;
revoke all on function public.current_staff_name() from public, anon;
grant execute on function public.current_staff_name() to authenticated;

-- Live totals for a counter (up to now while open, up to closing time after).
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
  if not found or not public.can_access_branch(c.branch_id) then
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
  where o.branch_id = c.branch_id
    and o.payment_status = 'Paid'
    and lower(o.status) <> 'cancelled'
    and o.paid_at >= c.opened_at and o.paid_at < v_end;

  select count(*) as n, coalesce(sum(o.total), 0) as amount
  into v_unpaid
  from public.orders o
  where o.branch_id = c.branch_id
    and o.payment_status <> 'Paid'
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
revoke all on function public.cash_counter_summary(uuid) from public, anon;
grant execute on function public.cash_counter_summary(uuid) to authenticated;

create or replace function public.open_cash_counter(p_branch_id uuid, p_opening_cash numeric)
returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid;
begin
  if not public.can_access_branch(p_branch_id) then
    raise exception 'Not allowed for this branch' using errcode = '42501';
  end if;
  if p_opening_cash is null or p_opening_cash < 0 then
    raise exception 'Opening cash must be 0 or more';
  end if;
  insert into public.cash_counters (branch_id, opened_by, opened_by_name, opening_cash)
  values (p_branch_id, auth.uid(), public.current_staff_name(), round(p_opening_cash, 2))
  returning id into v_id;
  return v_id;
exception when unique_violation then
  raise exception 'A cash counter is already open for this branch';
end;
$$;
revoke all on function public.open_cash_counter(uuid, numeric) from public, anon;
grant execute on function public.open_cash_counter(uuid, numeric) to authenticated;

create or replace function public.add_cash_counter_entry(
  p_counter_id uuid, p_kind text, p_amount numeric, p_reason text
) returns void language plpgsql security definer set search_path = '' as $$
declare c public.cash_counters;
begin
  select * into c from public.cash_counters where id = p_counter_id;
  if not found or not public.can_access_branch(c.branch_id) then
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
  insert into public.cash_counter_entries (counter_id, branch_id, kind, amount, reason, created_by, created_by_name)
  values (c.id, c.branch_id, p_kind, round(p_amount, 2), trim(coalesce(p_reason, '')), auth.uid(), public.current_staff_name());
end;
$$;
revoke all on function public.add_cash_counter_entry(uuid, text, numeric, text) from public, anon;
grant execute on function public.add_cash_counter_entry(uuid, text, numeric, text) to authenticated;

create or replace function public.close_cash_counter(p_counter_id uuid, p_counted_cash numeric, p_notes text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  c public.cash_counters;
  s jsonb;
begin
  select * into c from public.cash_counters where id = p_counter_id for update;
  if not found or not public.can_access_branch(c.branch_id) then
    raise exception 'Cash counter not found';
  end if;
  if c.status <> 'open' then
    raise exception 'This cash counter is already closed';
  end if;
  if p_counted_cash is null or p_counted_cash < 0 then
    raise exception 'Counted cash must be 0 or more';
  end if;

  -- Freeze the closing time first so the report covers exactly this shift.
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
revoke all on function public.close_cash_counter(uuid, numeric, text) from public, anon;
grant execute on function public.close_cash_counter(uuid, numeric, text) to authenticated;
