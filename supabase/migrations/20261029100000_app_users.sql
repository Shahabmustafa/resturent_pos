-- POS staff sign in with a username + password from this table instead of a
-- Supabase Auth email account. The app itself stays connected through one
-- hidden device account (so RLS and the branch functions keep working); this
-- table only decides who is using the till and what they may open.
create table if not exists public.app_users (
  id            uuid primary key default gen_random_uuid(),
  branch_id     uuid not null references public.branches(id) on delete cascade,
  name          text not null default '',
  username      text not null,
  password_hash text not null,
  role          public.branch_user_role not null default 'cashier',
  status        public.branch_user_status not null default 'active',
  created_at    timestamptz not null default now(),
  updated_at    timestamptz not null default now()
);

create unique index if not exists app_users_username_key on public.app_users (lower(username));

-- Password hashes never leave the database: no direct table access, RPCs only.
alter table public.app_users enable row level security;
revoke all on public.app_users from anon, authenticated;

create or replace function public._app_user_json(u public.app_users)
returns jsonb language sql immutable set search_path = '' as $$
  select jsonb_build_object(
    'id', u.id, 'branch_id', u.branch_id, 'name', u.name, 'username', u.username,
    'email', '', 'phone', null, 'role', u.role, 'status', u.status, 'avatar_url', null,
    'created_at', u.created_at, 'updated_at', u.updated_at);
$$;

-- Returns the user row (as JSON) for a correct username + password, else null.
create or replace function public.app_login(p_username text, p_password text)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare u public.app_users;
begin
  select * into u from public.app_users
   where lower(username) = lower(trim(p_username)) and status = 'active';
  if not found or u.password_hash <> crypt(p_password, u.password_hash) then
    return null;
  end if;
  return public._app_user_json(u);
end $$;

create or replace function public.app_list_users(p_branch_id uuid)
returns setof jsonb language sql security definer set search_path = public as $$
  select public._app_user_json(u) from public.app_users u
   where u.branch_id = p_branch_id order by u.created_at;
$$;

-- Creates (p_id null) or updates a user. An empty password keeps the old one.
create or replace function public.app_save_user(
  p_id uuid, p_branch_id uuid, p_name text, p_username text, p_password text,
  p_role text, p_status text)
returns jsonb language plpgsql security definer set search_path = public, extensions as $$
declare u public.app_users;
begin
  if p_id is null then
    if coalesce(p_password, '') = '' then raise exception 'Password is required'; end if;
    insert into public.app_users (branch_id, name, username, password_hash, role, status)
    values (p_branch_id, p_name, trim(p_username), crypt(p_password, gen_salt('bf')),
            p_role::public.branch_user_role, p_status::public.branch_user_status)
    returning * into u;
  else
    update public.app_users set
      name = p_name, username = trim(p_username),
      password_hash = case when coalesce(p_password, '') = '' then password_hash
                           else crypt(p_password, gen_salt('bf')) end,
      role = p_role::public.branch_user_role, status = p_status::public.branch_user_status,
      updated_at = now()
    where id = p_id returning * into u;
  end if;
  return public._app_user_json(u);
exception when unique_violation then
  raise exception 'That username is already taken';
end $$;

create or replace function public.app_set_user_status(p_id uuid, p_status text)
returns void language sql security definer set search_path = public as $$
  update public.app_users set status = p_status::public.branch_user_status, updated_at = now() where id = p_id;
$$;

create or replace function public.app_delete_user(p_id uuid)
returns void language sql security definer set search_path = public as $$
  delete from public.app_users where id = p_id;
$$;

revoke all on function public._app_user_json(public.app_users) from public, anon, authenticated;
revoke all on function public.app_login(text, text), public.app_list_users(uuid),
  public.app_save_user(uuid, uuid, text, text, text, text, text),
  public.app_set_user_status(uuid, text), public.app_delete_user(uuid) from public, anon;
grant execute on function public.app_login(text, text), public.app_list_users(uuid),
  public.app_save_user(uuid, uuid, text, text, text, text, text),
  public.app_set_user_status(uuid, text), public.app_delete_user(uuid) to authenticated;
