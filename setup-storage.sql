-- ════════════════════════════════════════════════════════════════
-- setup-storage.sql
-- Run ONCE in Supabase SQL Editor to enable profile photo uploads.
--
-- BEFORE running this SQL, also create the Storage bucket manually:
--   Supabase Dashboard → Storage → New bucket
--   Name: profile-photos
--   Public: YES (so photos can be displayed)
-- ════════════════════════════════════════════════════════════════

-- Allow anyone to upload photos into the profile-photos bucket
-- (the website uploads to a path like: {profileId}/photo1.jpg)
insert into storage.buckets (id, name, public)
values ('profile-photos', 'profile-photos', true)
on conflict (id) do update set public = true;

-- RLS: allow anon users to upload (insert) into profile-photos
create policy "allow_anon_photo_upload" on storage.objects
  for insert to anon
  with check (bucket_id = 'profile-photos');

-- RLS: allow anyone to read/view photos (public bucket)
create policy "allow_public_photo_read" on storage.objects
  for select to anon, authenticated
  using (bucket_id = 'profile-photos');

-- RLS: allow authenticated (admin) to delete photos
create policy "allow_admin_photo_delete" on storage.objects
  for delete to authenticated
  using (bucket_id = 'profile-photos');
