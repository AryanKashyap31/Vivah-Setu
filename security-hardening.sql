-- Run once in Supabase SQL Editor (after supabase-setup.sql)
-- Locks down public access, hides phone numbers, secures admin actions

-- ── 1. Public view: published profiles only, no phone/parent ──
create or replace view profiles_public as
select id, name, age, gen, gotra, kul, village, block, edu, job, ht, note, status
from profiles
where status = 'pub';

grant select on profiles_public to anon, authenticated;

-- ── 2. Admin RPC functions (password-checked, server-side) ──
create or replace function admin_verify_login(p_password text)
returns boolean
language sql
security definer
set search_path = public
as $$
  select exists (select 1 from settings where key = 'admin_pw' and value = p_password);
$$;

create or replace function admin_get_profiles(p_password text)
returns setof profiles
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from settings where key = 'admin_pw' and value = p_password) then
    raise exception 'Unauthorized';
  end if;
  return query select * from profiles order by id;
end;
$$;

create or replace function admin_approve_profile(p_password text, p_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from settings where key = 'admin_pw' and value = p_password) then
    raise exception 'Unauthorized';
  end if;
  update profiles set status = 'pub' where id = p_id;
end;
$$;

create or replace function admin_delete_profile(p_password text, p_id text)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from settings where key = 'admin_pw' and value = p_password) then
    raise exception 'Unauthorized';
  end if;
  delete from profiles where id = p_id;
end;
$$;

create or replace function admin_add_profile(p_password text, p_profile jsonb)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from settings where key = 'admin_pw' and value = p_password) then
    raise exception 'Unauthorized';
  end if;
  insert into profiles (id, name, age, gen, gotra, kul, village, block, edu, job, ht, phone, parent, note, status)
  values (
    p_profile->>'id',
    p_profile->>'name',
    (p_profile->>'age')::int,
    p_profile->>'gen',
    p_profile->>'gotra',
    coalesce(p_profile->>'kul', '—'),
    p_profile->>'village',
    coalesce(p_profile->>'block', 'Muzaffarpur'),
    p_profile->>'edu',
    coalesce(p_profile->>'job', '—'),
    coalesce(p_profile->>'ht', '—'),
    coalesce(p_profile->>'phone', ''),
    coalesce(p_profile->>'parent', ''),
    coalesce(p_profile->>'note', ''),
    coalesce(p_profile->>'status', 'pub')
  );
end;
$$;

create or replace function admin_save_settings(p_password text, p_wa text default null, p_new_pw text default null)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin
  if not exists (select 1 from settings where key = 'admin_pw' and value = p_password) then
    raise exception 'Unauthorized';
  end if;
  if p_wa is not null and p_wa <> '' then
    update settings set value = p_wa where key = 'admin_wa';
  end if;
  if p_new_pw is not null and p_new_pw <> '' then
    update settings set value = p_new_pw where key = 'admin_pw';
  end if;
end;
$$;

create or replace function get_next_profile_id()
returns text
language plpgsql
security definer
set search_path = public
as $$
declare max_n int;
begin
  select coalesce(max(cast(substring(id from 3) as int)), 0) into max_n from profiles;
  return 'MV' || lpad((max_n + 1)::text, 3, '0');
end;
$$;

grant execute on function admin_verify_login(text) to anon, authenticated;
grant execute on function admin_get_profiles(text) to anon, authenticated;
grant execute on function admin_approve_profile(text, text) to anon, authenticated;
grant execute on function admin_delete_profile(text, text) to anon, authenticated;
grant execute on function admin_add_profile(text, jsonb) to anon, authenticated;
grant execute on function admin_save_settings(text, text, text) to anon, authenticated;
grant execute on function get_next_profile_id() to anon, authenticated;

-- ── 3. Tighten RLS policies ──
drop policy if exists "profiles_select" on profiles;
drop policy if exists "profiles_insert" on profiles;
drop policy if exists "profiles_update" on profiles;
drop policy if exists "profiles_delete" on profiles;
drop policy if exists "settings_select" on settings;
drop policy if exists "settings_update" on settings;
drop policy if exists "settings_insert" on settings;

-- Public can only register (pending profiles only)
create policy "profiles_insert_pending" on profiles
  for insert to anon
  with check (status = 'pending');

-- Public can read admin WhatsApp number only
create policy "settings_read_wa" on settings
  for select to anon
  using (key = 'admin_wa');

-- ── 4. Revoke direct table access from anon ──
revoke select, update, delete on profiles from anon;
revoke select, insert, update on settings from anon;
grant insert on profiles to anon;
grant select on profiles_public to anon;
grant select on settings to anon; -- RLS limits to admin_wa row only

-- ── 5. Remove demo/sample profiles (safe — only deletes MV001–MV005) ──
delete from profiles where id in ('MV001', 'MV002', 'MV003', 'MV004', 'MV005');
