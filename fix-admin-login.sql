-- fix-admin-login.sql
-- Run ONCE in Supabase SQL Editor if admin login shows "Check internet connection"
-- Root cause: pgcrypto lives in the "extensions" schema on Supabase, but
-- admin_verify_login only had search_path = public, so crypt() was not found.

create extension if not exists pgcrypto with schema extensions;

-- Hash plain-text admin password (skip if already bcrypt)
update settings
set value = extensions.crypt(value, extensions.gen_salt('bf'))
where key = 'admin_pw' and value not like '$2%';

insert into settings (key, value) values
  ('admin_fail_count', '0'),
  ('admin_lock_until', '')
on conflict (key) do nothing;

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
    return false;
  end if;

  select value into v_hash from settings where key = 'admin_pw';

  if v_hash is not null and crypt(p_password, v_hash) = v_hash then
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

grant execute on function admin_verify_login(text) to anon, authenticated;
grant execute on function admin_save_settings(text, text, text) to anon, authenticated;

update settings
set value = extensions.crypt('admin123', extensions.gen_salt('bf'))
where key = 'admin_pw';

update settings
set value = '0'
where key = 'admin_fail_count';

update settings
set value = ''
where key = 'admin_lock_until';