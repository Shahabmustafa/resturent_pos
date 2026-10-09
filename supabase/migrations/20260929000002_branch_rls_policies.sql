-- Step 2: Row Level Security.
-- Branch user  -> sirf apni branch ka data.
-- Company owner -> apni company ki saari branches ka data.
-- anon (login ke baghair) -> kuch nahi.

-- ── Helper functions ──────────────────────────────────────────────────────
-- security definer: branch_users/companys ki RLS ko bypass karte hain, warna policies recursive ho jati hain.

create or replace function public.my_branch_id()
returns uuid language sql stable security definer set search_path = '' as $$
  select bu.branch_id from public.branch_users bu
  where bu.auth_user_id = (select auth.uid()) and bu.status = 'active'
  limit 1
$$;

create or replace function public.my_branch_role()
returns text language sql stable security definer set search_path = '' as $$
  select bu.role::text from public.branch_users bu
  where bu.auth_user_id = (select auth.uid()) and bu.status = 'active'
  limit 1
$$;

create or replace function public.my_company_id()
returns uuid language sql stable security definer set search_path = '' as $$
  select c.id from public.companys c
  where c.auth_user_id = (select auth.uid()) and c.is_active
  limit 1
$$;

create or replace function public.can_access_branch(p_branch_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select p_branch_id is not null and (
    p_branch_id = public.my_branch_id()
    or exists (
      select 1 from public.branches b
      where b.id = p_branch_id and b.company_id = public.my_company_id()
    )
  )
$$;

-- Kuch purani tables mein branch_id text hai
create or replace function public.can_access_branch_text(p_branch_id text)
returns boolean language sql stable security definer set search_path = '' as $$
  select case
    when p_branch_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
      then public.can_access_branch(p_branch_id::uuid)
    else false
  end
$$;

-- Users add/edit kar sakta hai: branch ka admin/manager ya company owner
create or replace function public.can_manage_branch(p_branch_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select p_branch_id is not null and (
    (p_branch_id = public.my_branch_id() and public.my_branch_role() in ('admin', 'manager'))
    or exists (
      select 1 from public.branches b
      where b.id = p_branch_id and b.company_id = public.my_company_id()
    )
  )
$$;

revoke all on function public.my_branch_id(), public.my_branch_role(), public.my_company_id(),
  public.can_access_branch(uuid), public.can_access_branch_text(text), public.can_manage_branch(uuid)
  from public, anon;
grant execute on function public.my_branch_id(), public.my_branch_role(), public.my_company_id(),
  public.can_access_branch(uuid), public.can_access_branch_text(text), public.can_manage_branch(uuid)
  to authenticated;

-- ── Purani "sab ko ijazat" policies hatao ─────────────────────────────────
do $$
declare p record;
begin
  for p in select policyname, tablename from pg_policies where schemaname = 'public' loop
    execute format('drop policy %I on public.%I', p.policyname, p.tablename);
  end loop;
end $$;

-- ── RLS on for every table ────────────────────────────────────────────────
alter table public.companys              enable row level security;
alter table public.branches              enable row level security;
alter table public.branch_users          enable row level security;
alter table public.tables                enable row level security;
alter table public.customers             enable row level security;
alter table public.categories            enable row level security;
alter table public.menu_items            enable row level security;
alter table public.menu_item_sizes       enable row level security;
alter table public.menu_item_ingredients enable row level security;
alter table public.deals                 enable row level security;
alter table public.deal_items            enable row level security;
alter table public.deal_sizes            enable row level security;
alter table public.orders                enable row level security;
alter table public.order_items           enable row level security;
alter table public.riders                enable row level security;
alter table public.delivery_orders       enable row level security;
alter table public.suppliers             enable row level security;
alter table public.supplier_transactions enable row level security;
alter table public.stock_items           enable row level security;
alter table public.branch_cash           enable row level security;
alter table public.cash_transactions     enable row level security;
alter table public.receipt_settings      enable row level security;
alter table public.branch_tax_settings   enable row level security;
alter table public.branch_tax_slabs      enable row level security;

-- ── Tables with branch_id uuid ────────────────────────────────────────────
do $$
declare t text;
begin
  foreach t in array array[
    'tables', 'customers', 'categories', 'menu_items', 'deals', 'orders', 'order_items',
    'riders', 'delivery_orders', 'branch_tax_settings', 'branch_tax_slabs'
  ] loop
    execute format(
      'create policy branch_access on public.%I for all to authenticated
         using (public.can_access_branch(branch_id))
         with check (public.can_access_branch(branch_id))', t);
  end loop;
end $$;

-- ── Tables with branch_id text ────────────────────────────────────────────
do $$
declare t text;
begin
  foreach t in array array[
    'suppliers', 'supplier_transactions', 'stock_items', 'branch_cash',
    'cash_transactions', 'receipt_settings', 'menu_item_ingredients'
  ] loop
    execute format(
      'create policy branch_access on public.%I for all to authenticated
         using (public.can_access_branch_text(branch_id))
         with check (public.can_access_branch_text(branch_id))', t);
  end loop;
end $$;

-- ── Child tables (no branch_id column) ────────────────────────────────────
create policy branch_access on public.menu_item_sizes for all to authenticated
  using (exists (select 1 from public.menu_items m where m.id = menu_item_id and public.can_access_branch(m.branch_id)))
  with check (exists (select 1 from public.menu_items m where m.id = menu_item_id and public.can_access_branch(m.branch_id)));

create policy branch_access on public.deal_items for all to authenticated
  using (exists (select 1 from public.deals d where d.id = deal_id and public.can_access_branch(d.branch_id)))
  with check (exists (select 1 from public.deals d where d.id = deal_id and public.can_access_branch(d.branch_id)));

create policy branch_access on public.deal_sizes for all to authenticated
  using (exists (select 1 from public.deals d where d.id = deal_id and public.can_access_branch(d.branch_id)))
  with check (exists (select 1 from public.deals d where d.id = deal_id and public.can_access_branch(d.branch_id)));

-- ── branches ──────────────────────────────────────────────────────────────
create policy branches_select on public.branches for select to authenticated
  using (public.can_access_branch(id));
create policy branches_update on public.branches for update to authenticated
  using (public.can_manage_branch(id))
  with check (public.can_manage_branch(id));
create policy branches_insert on public.branches for insert to authenticated
  with check (company_id = public.my_company_id());
create policy branches_delete on public.branches for delete to authenticated
  using (company_id = public.my_company_id());

-- ── companys ──────────────────────────────────────────────────────────────
create policy companys_select on public.companys for select to authenticated
  using (
    id = public.my_company_id()
    or id = (select b.company_id from public.branches b where b.id = public.my_branch_id())
  );
create policy companys_update on public.companys for update to authenticated
  using (id = public.my_company_id())
  with check (id = public.my_company_id());
-- Company ka owner account, plan aur status sirf service role badal sakta hai
revoke update on public.companys from authenticated;
grant update (name, phone, logo_url, city, address) on public.companys to authenticated;

-- ── branch_users ──────────────────────────────────────────────────────────
-- Insert/delete aur email/password badalna sirf Edge Function (manage-branch-user) se.
create policy branch_users_select on public.branch_users for select to authenticated
  using (public.can_access_branch(branch_id));
create policy branch_users_update on public.branch_users for update to authenticated
  using (public.can_manage_branch(branch_id))
  with check (
    public.can_manage_branch(branch_id)
    -- manager kisi ko admin nahi bana sakta
    and (role <> 'admin' or public.my_branch_role() = 'admin' or public.my_company_id() is not null)
  );
revoke insert, delete, update on public.branch_users from authenticated;
grant update (name, username, phone, role, status, avatar_url) on public.branch_users to authenticated;

-- ── Functions ─────────────────────────────────────────────────────────────
create or replace function public.update_branch_cash(
  p_branch_id text, p_amount numeric, p_type text,
  p_ref_id bigint default null, p_ref_label text default null, p_note text default null
) returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.can_access_branch_text(p_branch_id) then
    raise exception 'Not allowed for this branch' using errcode = '42501';
  end if;

  insert into public.branch_cash(branch_id, balance, updated_at)
    values (p_branch_id, p_amount, now())
  on conflict (branch_id)
    do update set
      balance    = public.branch_cash.balance + p_amount,
      updated_at = now();

  insert into public.cash_transactions(
    branch_id, type, ref_id, ref_label, amount, direction, note
  ) values (
    p_branch_id, p_type, p_ref_id, p_ref_label,
    abs(p_amount),
    case when p_amount >= 0 then 'in' else 'out' end,
    p_note
  );
end;
$$;

revoke all on function public.update_branch_cash(text, numeric, text, bigint, text, text) from public, anon;
grant execute on function public.update_branch_cash(text, numeric, text, bigint, text, text) to authenticated;
revoke all on function public.increment_supplier_paid(bigint, numeric) from public, anon;
revoke all on function public.increment_supplier_biz(bigint, numeric) from public, anon;
grant execute on function public.increment_supplier_paid(bigint, numeric) to authenticated;
grant execute on function public.increment_supplier_biz(bigint, numeric) to authenticated;

-- ── Storage: upload/edit/delete sirf logged-in users ──────────────────────
drop policy if exists "Allow uploads" on storage.objects;
drop policy if exists "Allow delete" on storage.objects;
drop policy if exists "Allow public uploads receipt_image" on storage.objects;
drop policy if exists "Allow public update receipt_image" on storage.objects;
drop policy if exists "Allow anon upload receipt_image" on storage.objects;
drop policy if exists "Allow anon update receipt_image" on storage.objects;

create policy "POS users upload images" on storage.objects for insert to authenticated
  with check (bucket_id in ('menu-images', 'receipt_image'));
create policy "POS users update images" on storage.objects for update to authenticated
  using (bucket_id in ('menu-images', 'receipt_image'));
create policy "POS users delete images" on storage.objects for delete to authenticated
  using (bucket_id in ('menu-images', 'receipt_image'));
