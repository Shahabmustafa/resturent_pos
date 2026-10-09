-- Website profile photos.
--   * public "avatars" bucket (anyone can view a photo by URL)
--   * max 2 MB, JPG / PNG / WebP only
--   * a signed-in user can only add, replace or remove files in their own
--     folder: avatars/<auth user id>/...

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values ('avatars', 'avatars', true, 2097152, array['image/jpeg', 'image/png', 'image/webp'])
on conflict (id) do update
  set public = excluded.public,
      file_size_limit = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Users read own avatar files" on storage.objects;
drop policy if exists "Users upload own avatar" on storage.objects;
drop policy if exists "Users update own avatar" on storage.objects;
drop policy if exists "Users delete own avatar" on storage.objects;

create policy "Users read own avatar files" on storage.objects for select to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Users upload own avatar" on storage.objects for insert to authenticated
  with check (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Users update own avatar" on storage.objects for update to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
create policy "Users delete own avatar" on storage.objects for delete to authenticated
  using (bucket_id = 'avatars' and (storage.foldername(name))[1] = (select auth.uid())::text);
