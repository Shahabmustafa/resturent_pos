-- Step 3: Sirf tab chalayen jab Supabase Auth se login test ho chuka ho.
-- Passwords ab auth.users mein (bcrypt) hain. Plain-text columns hata do.

alter table public.branch_users drop column if exists password;
alter table public.companys     drop column if exists password_hash;
