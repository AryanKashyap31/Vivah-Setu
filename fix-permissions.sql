-- Run this in Supabase SQL Editor if profiles don't load (permission error)
-- Safe to run even if you already ran supabase-setup.sql

grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.profiles to anon, authenticated;
grant select, insert, update on public.settings to anon, authenticated;
