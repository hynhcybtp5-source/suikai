begin;
alter table public.profiles
  add column if not exists viber_phone text;
grant update (
  name,
  phone,
  email,
  avatar_media_id,
  city,
  city_id,
  viber_phone
) on table public.profiles to authenticated;
commit;
