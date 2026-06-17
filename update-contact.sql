-- Run once in Supabase SQL Editor to set admin WhatsApp contact number
update settings set value = '918340363036' where key = 'admin_wa';
insert into settings (key, value) values ('admin_wa', '918340363036')
on conflict (key) do update set value = excluded.value;
