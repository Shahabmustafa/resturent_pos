-- Step 1: Link POS users (branch_users) and company owners (companys) to Supabase Auth.
-- Existing accounts get a temporary email: <username>@pizzahouse.pos
-- The password stays the same as the one currently in the table.

alter table public.branch_users
  add column if not exists email text,
  add column if not exists auth_user_id uuid unique references auth.users(id) on delete set null;
alter table public.companys
  add column if not exists email text,
  add column if not exists auth_user_id uuid unique references auth.users(id) on delete set null;

create unique index if not exists branch_users_email_key on public.branch_users (lower(email));
create unique index if not exists companys_email_key on public.companys (lower(email));

-- Duplicate FK (branch_users_branch_id_fkey already exists)
alter table public.branch_users drop constraint if exists fk_branch_users_branch;

update public.branch_users set email = lower(username) || '@pizzahouse.pos' where email is null;
update public.companys     set email = lower(username) || '@pizzahouse.pos' where email is null;

do $$
declare
  r record;
  v_uid uuid;
begin
  for r in
    select 'branch_users' as src, id, email, password as pw from public.branch_users where auth_user_id is null
    union all
    select 'companys', id, email, password_hash from public.companys where auth_user_id is null
  loop
    v_uid := gen_random_uuid();

    insert into auth.users (
      instance_id, id, aud, role, email, encrypted_password, email_confirmed_at,
      raw_app_meta_data, raw_user_meta_data, created_at, updated_at,
      confirmation_token, recovery_token, email_change_token_new, email_change,
      email_change_token_current, phone_change, phone_change_token, reauthentication_token
    ) values (
      '00000000-0000-0000-0000-000000000000', v_uid, 'authenticated', 'authenticated', r.email,
      extensions.crypt(r.pw, extensions.gen_salt('bf')), now(),
      '{"provider":"email","providers":["email"]}'::jsonb, '{}'::jsonb, now(), now(),
      '', '', '', '', '', '', '', ''
    );

    insert into auth.identities (id, provider_id, user_id, identity_data, provider, last_sign_in_at, created_at, updated_at)
    values (
      gen_random_uuid(), v_uid::text, v_uid,
      jsonb_build_object('sub', v_uid::text, 'email', r.email, 'email_verified', true),
      'email', now(), now(), now()
    );

    if r.src = 'branch_users' then
      update public.branch_users set auth_user_id = v_uid where id = r.id;
    else
      update public.companys set auth_user_id = v_uid where id = r.id;
    end if;
  end loop;
end $$;

alter table public.branch_users alter column email set not null;

-- New users are created via the Edge Function (manage-branch-user), so the password column is now optional.
-- The column is dropped in step 3, once login has been tested.
alter table public.branch_users alter column password drop not null;
alter table public.companys     alter column password_hash drop not null;

-- Old login RPCs (verify_branch_login was already broken: branches.username does not exist)
drop function if exists public.verify_company_login(text, text);
drop function if exists public.verify_branch_login(text, text, uuid);
