-- ════════════════════════════════════════════════════════════════
-- security-hardening-v2.sql
-- Run ONCE in Supabase SQL Editor, AFTER security-hardening.sql
-- Safe to re-run (idempotent).
--
-- What this does:
--  1. Hashes the admin password (bcrypt) instead of storing plain text
--  2. Adds login lockout (5 wrong tries -> 15 min lock)
--  3. Prevents duplicate "pending" submissions from the same phone number
-- ════════════════════════════════════════════════════════════════

-- ── 1. Enable bcrypt (Supabase installs pgcrypto in the extensions schema) ──
create extension if not exists pgcrypto with schema extensions;

-- ── 2. Hash the existing admin password (only if it's still plain text) ──
update settings
set value = extensions.crypt(value, extensions.gen_salt('bf'))
where key = 'admin_pw' and value not like '$2%';

-- ── 3. Lockout tracking rows ──
insert into settings (key, value) values
  ('admin_fail_count', '0'),
  ('admin_lock_until', '')
on conflict (key) do nothing;

-- ── 4. Replace admin_verify_login with hashed + lockout-aware version ──
create or replace function admin_verify_login(p_password text)
returns boolean
language plpgsql
security definer
set search_path = public, extensions
as $$
declare
  v_hash text;
  v_fail int;
  v_lock text;
begin
  select value into v_lock from settings where key = 'admin_lock_until';
  if v_lock is not null and v_lock <> '' and v_lock::timestamptz > now() then
    return false; -- still locked out
  end if;

  select value into v_hash from settings where key = 'admin_pw';

  if v_hash is not null and crypt(p_password, v_hash) = v_hash then
    -- success: reset failure counter
    update settings set value = '0' where key = 'admin_fail_count';
    update settings set value = '' where key = 'admin_lock_until';
    return true;
  else
    select coalesce(value::int, 0) into v_fail from settings where key = 'admin_fail_count';
    v_fail := v_fail + 1;
    update settings set value = v_fail::text where key = 'admin_fail_count';
    if v_fail >= 5 then
      update settings set value = (now() + interval '15 minutes')::text where key = 'admin_lock_until';
      update settings set value = '0' where key = 'admin_fail_count';
    end if;
    return false;
  end if;
end;
$$;

-- ── 5. Update every admin_* function that does its own password check ──
create or replace function admin_get_profiles(p_password text)
returns setof profiles
language plpgsql
security definer
set search_path = public
as $$
begin
  if not admin_verify_login(p_password) then
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
  if not admin_verify_login(p_password) then
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
  if not admin_verify_login(p_password) then
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
  if not admin_verify_login(p_password) then
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
set search_path = public, extensions
as $$
begin
  if not admin_verify_login(p_password) then
    raise exception 'Unauthorized';
  end if;
  if p_wa is not null and p_wa <> '' then
    update settings set value = p_wa where key = 'admin_wa';
  end if;
  if p_new_pw is not null and p_new_pw <> '' then
    update settings set value = crypt(p_new_pw, gen_salt('bf')) where key = 'admin_pw';
  end if;
end;
$$;

-- IMPORTANT: admin_save_settings now stores the HASH of the new password.
-- The app keeps the plain password you typed in memory for that session
-- (so it can keep calling other admin_ functions), but admin_verify_login
-- compares it against the bcrypt hash via crypt(), so this still works
-- correctly on next login.

-- ── 6. Stop duplicate "pending" submissions from the same phone number ──
-- (one pending request per phone number at a time; admin can still add
--  multiple profiles manually with the same phone if needed)
drop index if exists uniq_pending_phone;
create unique index uniq_pending_phone on profiles (phone)
  where status = 'pending' and phone <> '';
