-- Step 3: Run only after login via Supabase Auth has been tested.
-- Passwords now live in auth.users (bcrypt). Drop the plain-text columns.

alter table public.branch_users drop column if exists password;
alter table public.companys     drop column if exists password_hash;
