-- Incoming phone calls (from the caller-ID box) shown as a call log and popup on the till.
create table if not exists public.call_log (
  id        uuid primary key default gen_random_uuid(),
  phone     text not null,
  called_at timestamptz not null default now()
);

create index if not exists call_log_called_at_idx on public.call_log (called_at desc);

alter table public.call_log enable row level security;
create policy staff_access on public.call_log for all to authenticated
  using (public.is_pos_staff()) with check (public.is_pos_staff());

-- The till gets new calls live.
alter publication supabase_realtime add table public.call_log;
