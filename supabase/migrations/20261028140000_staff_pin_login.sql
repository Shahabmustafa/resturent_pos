-- PIN unlock for the POS lock screen.
--   * The till stays signed in to the branch account; staff unlock it with a PIN.
--   * A PIN belongs to one staff member and is unique within the branch.
--   * Only the bcrypt hash is stored, in its own table with no read access, so a
--     hash can never be fetched through the API (a 4-digit PIN is easy to crack offline).
--   * set_staff_pin: admin / manager only.  verify_staff_pin: any signed-in staff of
--     the branch; 5 wrong tries in 5 minutes lock further tries for a while.

create extension if not exists pgcrypto with schema extensions;

create table if not exists public.branch_user_pins (
  user_id  uuid primary key references public.branch_users(id) on delete cascade,
  pin_hash text not null
);
alter table public.branch_user_pins enable row level security; -- no policies: functions only

create table if not exists public.staff_pin_attempts (
  id           bigserial primary key,
  auth_user_id uuid not null,
  attempted_at timestamptz not null default now()
);
alter table public.staff_pin_attempts enable row level security; -- no policies: functions only
create index if not exists staff_pin_attempts_user_idx on public.staff_pin_attempts (auth_user_id, attempted_at);

create or replace function public.set_staff_pin(p_user_id uuid, p_pin text)
returns void language plpgsql security definer set search_path = '' as $$
declare
  v_branch uuid;
  v_role   text;
  r        record;
begin
  select bu.branch_id, bu.role into v_branch, v_role
  from public.branch_users bu where bu.auth_user_id = (select auth.uid()) and bu.status = 'active';
  if v_branch is null or lower(v_role) not in ('admin', 'manager') then
    raise exception 'Not allowed' using errcode = '42501';
  end if;
  if not exists (select 1 from public.branch_users where id = p_user_id and branch_id = v_branch) then
    raise exception 'User not found';
  end if;
  if p_pin is null or p_pin !~ '^[0-9]{4,8}$' then
    raise exception 'PIN must be 4 to 8 digits';
  end if;
  for r in
    select p.user_id, p.pin_hash from public.branch_user_pins p
    join public.branch_users bu on bu.id = p.user_id
    where bu.branch_id = v_branch and p.user_id <> p_user_id
  loop
    if r.pin_hash = extensions.crypt(p_pin, r.pin_hash) then
      raise exception 'This PIN is already used by another user';
    end if;
  end loop;
  insert into public.branch_user_pins (user_id, pin_hash)
  values (p_user_id, extensions.crypt(p_pin, extensions.gen_salt('bf')))
  on conflict (user_id) do update set pin_hash = excluded.pin_hash;
end;
$$;
revoke all on function public.set_staff_pin(uuid, text) from public, anon;
grant execute on function public.set_staff_pin(uuid, text) to authenticated;

-- Returns the matching active staff member (a branch_users row) or null for a wrong PIN.
create or replace function public.verify_staff_pin(p_pin text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare
  v_uid    uuid := (select auth.uid());
  v_branch uuid;
  v_fails  int;
  r        record;
begin
  if v_uid is null then
    raise exception 'Please sign in' using errcode = '42501';
  end if;
  select branch_id into v_branch from public.branch_users where auth_user_id = v_uid;
  if v_branch is null then
    raise exception 'This account is not linked to a branch';
  end if;

  select count(*) into v_fails from public.staff_pin_attempts
  where auth_user_id = v_uid and attempted_at > now() - interval '5 minutes';
  if v_fails >= 5 then
    raise exception 'Too many wrong PINs. Try again in a few minutes';
  end if;

  for r in
    select bu.id, p.pin_hash from public.branch_users bu
    join public.branch_user_pins p on p.user_id = bu.id
    where bu.branch_id = v_branch and bu.status = 'active'
  loop
    if r.pin_hash = extensions.crypt(p_pin, r.pin_hash) then
      delete from public.staff_pin_attempts where auth_user_id = v_uid;
      return (select to_jsonb(bu) from public.branch_users bu where bu.id = r.id);
    end if;
  end loop;

  insert into public.staff_pin_attempts (auth_user_id) values (v_uid);
  delete from public.staff_pin_attempts where attempted_at < now() - interval '1 day';
  return null;
end;
$$;
revoke all on function public.verify_staff_pin(text) from public, anon;
grant execute on function public.verify_staff_pin(text) to authenticated;
