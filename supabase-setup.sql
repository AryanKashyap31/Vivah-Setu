-- Run this once in Supabase: SQL Editor → New query → Paste → Run

create table if not exists profiles (
  id text primary key,
  name text not null,
  age int not null,
  gen text not null,
  gotra text,
  kul text,
  village text,
  block text,
  edu text,
  job text,
  ht text,
  phone text,
  parent text,
  note text,
  status text not null default 'pending'
);

create table if not exists settings (
  key text primary key,
  value text not null default ''
);

insert into settings (key, value) values
  ('admin_pw', 'admin123'),
  ('admin_wa', '918340363036')
on conflict (key) do nothing;

insert into profiles (id, name, age, gen, gotra, kul, village, block, edu, job, ht, phone, parent, note, status) values
  ('MV001', 'Rahul Kumar Sharma', 27, 'Var', 'Kashyap', 'Mishra', 'Sahpur Patori', 'Muraul', 'Engineering', 'Software Engineer, Bengaluru', '5''9"', '9876543210', 'Ramesh Kumar', 'Working in IT sector since 5 years.', 'pub'),
  ('MV002', 'Priya Kumari Singh', 23, 'Vadhu', 'Bharadwaj', 'Pandey', 'Rampur Dumra', 'Dumra', 'Graduate (BA/BSc/BCom)', 'Primary Teacher, Muzaffarpur', '5''3"', '9876500001', 'Suresh Singh', '', 'pub'),
  ('MV003', 'Amit Chandra Mishra', 30, 'Var', 'Vashishtha', 'Rai', 'Bariyarpur', 'Sakra', 'MBA / Management', 'Bank Manager, SBI Patna', '5''8"', '9876500002', 'Chandrakant Mishra', 'Posted in Patna, native of Muzaffarpur.', 'pub'),
  ('MV004', 'Sunita Devi Pandey', 25, 'Vadhu', 'Shandilya', 'Tiwari', 'Mahua', 'Motipur', 'MA / MSc / MCom', 'B.Ed ongoing', '5''2"', '9876500003', 'Vijay Pandey', '', 'pub'),
  ('MV005', 'Vivek Narayan Rai', 29, 'Var', 'Gautam', 'Ojha', 'Kanti', 'Kanti', 'Medical (MBBS)', 'Doctor, SKMCH Muzaffarpur', '5''10"', '9876500004', 'Narayan Rai', 'MBBS from IGIMS Patna.', 'pub')
on conflict (id) do nothing;

alter table profiles enable row level security;
alter table settings enable row level security;

create policy "profiles_select" on profiles for select using (true);
create policy "profiles_insert" on profiles for insert with check (true);
create policy "profiles_update" on profiles for update using (true);
create policy "profiles_delete" on profiles for delete using (true);

create policy "settings_select" on settings for select using (true);
create policy "settings_update" on settings for update using (true);
create policy "settings_insert" on settings for insert with check (true);

-- Required so the website can read/write data (run this if you get permission errors)
grant usage on schema public to anon, authenticated;
grant select, insert, update, delete on public.profiles to anon, authenticated;
grant select, insert, update on public.settings to anon, authenticated;
