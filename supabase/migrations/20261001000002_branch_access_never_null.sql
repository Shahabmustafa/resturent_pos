-- Security fix: the branch-access helpers returned NULL (not false) for users
-- with no branch/company — e.g. any website customer. RLS treats NULL as "no",
-- but functions written as `if not public.can_access_branch(x) then raise …`
-- evaluate `not NULL` = NULL and skip the check, so a signed-up customer could
-- call update_branch_cash, open_cash_counter, dashboard_stats, etc.
-- coalesce(…, false) makes them strictly true/false; staff access is unchanged.

create or replace function public.can_access_branch(p_branch_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce(
    p_branch_id is not null and (
      p_branch_id = public.my_branch_id()
      or exists (
        select 1 from public.branches b
        where b.id = p_branch_id and b.company_id = public.my_company_id()
      )
    ),
    false
  )
$$;

create or replace function public.can_access_branch_text(p_branch_id text)
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce(
    case
      when p_branch_id ~* '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$'
        then public.can_access_branch(p_branch_id::uuid)
      else false
    end,
    false
  )
$$;

create or replace function public.can_manage_branch(p_branch_id uuid)
returns boolean language sql stable security definer set search_path = '' as $$
  select coalesce(
    p_branch_id is not null and (
      (p_branch_id = public.my_branch_id() and public.my_branch_role() in ('admin', 'manager'))
      or exists (
        select 1 from public.branches b
        where b.id = p_branch_id and b.company_id = public.my_company_id()
      )
    ),
    false
  )
$$;
