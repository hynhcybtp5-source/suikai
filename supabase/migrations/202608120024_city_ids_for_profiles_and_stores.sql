begin;
alter table public.profiles
  add column if not exists city_id uuid references public.cities(id) on delete set null;
alter table public.stores
  add column if not exists city_id uuid references public.cities(id) on delete set null;
create index if not exists profiles_city_id_idx on public.profiles(city_id);
create index if not exists stores_city_id_idx on public.stores(city_id);
create or replace function public.handle_new_auth_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  requested_city_id uuid;
begin
  begin
    requested_city_id := nullif(new.raw_user_meta_data ->> 'city_id', '')::uuid;
  exception when invalid_text_representation then
    requested_city_id := null;
  end;

  if requested_city_id is not null and not exists (
    select 1 from public.cities c
    where c.id = requested_city_id and c.is_active = true
  ) then
    requested_city_id := null;
  end if;

  insert into public.profiles (id, name, phone, email, city_id)
  values (
    new.id,
    nullif(btrim(coalesce(new.raw_user_meta_data ->> 'name',
      new.raw_user_meta_data ->> 'full_name', '')), ''),
    nullif(btrim(coalesce(new.phone,
      new.raw_user_meta_data ->> 'phone', '')), ''),
    nullif(lower(btrim(coalesce(new.email, ''))), ''),
    requested_city_id
  )
  on conflict (id) do nothing;
  return new;
end;
$$;
create or replace function public.get_public_stores()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(
    jsonb_build_object(
      'id', s.id,
      'name', s.name,
      'logo_url', s.logo_url,
      'cover_url', s.cover_url,
      'description', s.description,
      'category_id', s.category_id,
      'phone', s.phone,
      'viber_phone', s.viber_phone,
      'city', s.city,
      'city_id', s.city_id,
      'cities', case when c.id is null then null else jsonb_build_object(
        'id', c.id, 'name', c.name, 'name_th', c.name_th,
        'name_shn', c.name_shn, 'name_en', c.name_en,
        'name_my', c.name_my, 'is_active', c.is_active
      ) end,
      'location', s.location,
      'opening_time', s.opening_time,
      'closing_time', s.closing_time,
      'status', s.status,
      'lifecycle_status', s.lifecycle_status,
      'latitude', s.latitude,
      'longitude', s.longitude,
      'is_promoted', s.is_promoted,
      'promotion_start_at', s.promotion_start_at,
      'promotion_end_at', s.promotion_end_at,
      'is_hidden', false,
      'deleted_at', null,
      'created_at', s.created_at
    ) order by s.created_at desc
  ), '[]'::jsonb)
  from public.stores s
  left join public.cities c on c.id = s.city_id
  where s.status = 'approved'
    and s.lifecycle_status = 'active'
    and s.is_hidden = false
    and s.deleted_at is null;
$$;
revoke all on function public.get_public_stores() from public;
grant execute on function public.get_public_stores()
to anon, authenticated, service_role;
commit;
