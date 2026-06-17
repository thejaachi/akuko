-- =====================================================================
-- Akuko — 0004_storage.sql
-- Storage buckets + RLS policies on storage.objects.
--
-- Buckets:
--   * book-files  (private) : epub/pdf. Access ONLY via signed URLs issued
--                             by the signed-url edge function after a
--                             premium/subscription check. No public read.
--   * book-covers (public)  : cover images. Public read, admin write.
--   * avatars     (public)  : profile pictures. Public read, owner write,
--                             keyed by a top-level folder = the user's uid.
-- =====================================================================

-- ---------------------------------------------------------------------
-- Create buckets (idempotent)
-- ---------------------------------------------------------------------
insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values
  ('book-files', 'book-files', false, 524288000,  -- 500 MB
   array['application/epub+zip','application/pdf']),
  ('book-covers', 'book-covers', true, 10485760,   -- 10 MB
   array['image/png','image/jpeg','image/webp']),
  ('avatars', 'avatars', true, 5242880,            -- 5 MB
   array['image/png','image/jpeg','image/webp'])
on conflict (id) do update
  set public            = excluded.public,
      file_size_limit   = excluded.file_size_limit,
      allowed_mime_types = excluded.allowed_mime_types;

-- =====================================================================
-- book-files : private. Service role (signed-url function) bypasses RLS.
-- Admins may upload/manage files directly. No anon/auth direct read.
-- =====================================================================
drop policy if exists "book-files admin read"   on storage.objects;
drop policy if exists "book-files admin write"   on storage.objects;
drop policy if exists "book-files admin update"  on storage.objects;
drop policy if exists "book-files admin delete"  on storage.objects;

create policy "book-files admin read" on storage.objects
  for select to authenticated
  using (bucket_id = 'book-files' and public.is_admin());

create policy "book-files admin write" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'book-files' and public.is_admin());

create policy "book-files admin update" on storage.objects
  for update to authenticated
  using (bucket_id = 'book-files' and public.is_admin())
  with check (bucket_id = 'book-files' and public.is_admin());

create policy "book-files admin delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'book-files' and public.is_admin());

-- NOTE: End users never read book-files directly. The `signed-url` edge
-- function (service role) validates premium/subscription entitlement and
-- returns a short-lived signed URL.

-- =====================================================================
-- book-covers : public read, admin write
-- =====================================================================
drop policy if exists "book-covers public read"  on storage.objects;
drop policy if exists "book-covers admin write"   on storage.objects;
drop policy if exists "book-covers admin update"  on storage.objects;
drop policy if exists "book-covers admin delete"  on storage.objects;

create policy "book-covers public read" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'book-covers');

create policy "book-covers admin write" on storage.objects
  for insert to authenticated
  with check (bucket_id = 'book-covers' and public.is_admin());

create policy "book-covers admin update" on storage.objects
  for update to authenticated
  using (bucket_id = 'book-covers' and public.is_admin())
  with check (bucket_id = 'book-covers' and public.is_admin());

create policy "book-covers admin delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'book-covers' and public.is_admin());

-- =====================================================================
-- avatars : public read, owner write.
-- Objects are stored under a folder named with the owner's uid:
--   avatars/<uid>/<filename>
-- so storage.foldername(name)[1] = the owning user's id.
-- =====================================================================
drop policy if exists "avatars public read"   on storage.objects;
drop policy if exists "avatars owner write"    on storage.objects;
drop policy if exists "avatars owner update"   on storage.objects;
drop policy if exists "avatars owner delete"   on storage.objects;

create policy "avatars public read" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'avatars');

create policy "avatars owner write" on storage.objects
  for insert to authenticated
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars owner update" on storage.objects
  for update to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  )
  with check (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );

create policy "avatars owner delete" on storage.objects
  for delete to authenticated
  using (
    bucket_id = 'avatars'
    and (storage.foldername(name))[1] = auth.uid()::text
  );
