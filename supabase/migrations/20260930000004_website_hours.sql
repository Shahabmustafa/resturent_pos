-- Website shows the opening hours set in the POS (Settings → Company → Working hours).
-- Only the hours are exposed; the rest of the branches row (NTN, STRN, …) stays private.
create or replace function public.website_hours()
returns table (opening_time text, closing_time text, is_24_hours boolean)
language sql stable security definer set search_path = '' as $$
  select b.opening_time::text, b.closing_time::text, coalesce(b.is_24_hours, false)
  from public.branches b
  where b.id = public.website_branch_id()
$$;

revoke all on function public.website_hours() from public;
grant execute on function public.website_hours() to anon, authenticated;
