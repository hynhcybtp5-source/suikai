begin;
alter table public.profiles
  add column if not exists city text;
create or replace function public.handle_new_auth_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  submitted_city text;
begin
  submitted_city := nullif(btrim(coalesce(new.raw_user_meta_data ->> 'city', '')), '');

  insert into public.profiles (id, name, phone, email, city)
  values (
    new.id,
    nullif(btrim(coalesce(new.raw_user_meta_data ->> 'name',
      new.raw_user_meta_data ->> 'full_name', '')), ''),
    nullif(btrim(coalesce(new.phone,
      new.raw_user_meta_data ->> 'phone', '')), ''),
    nullif(lower(btrim(coalesce(new.email, ''))), ''),
    submitted_city
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
commit;
