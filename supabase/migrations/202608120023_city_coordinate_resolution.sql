begin;
alter table public.cities
  add column if not exists latitude double precision,
  add column if not exists longitude double precision;
alter table public.cities drop constraint if exists cities_latitude_check;
alter table public.cities add constraint cities_latitude_check
  check (latitude is null or latitude between -90 and 90);
alter table public.cities drop constraint if exists cities_longitude_check;
alter table public.cities add constraint cities_longitude_check
  check (longitude is null or longitude between -180 and 180);
create or replace function public.resolve_city_for_coordinates(
  p_latitude double precision,
  p_longitude double precision
)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select case when candidate.distance_km <= 100 then
    jsonb_build_object(
      'id', candidate.id,
      'name', candidate.name,
      'name_th', candidate.name_th,
      'name_shn', candidate.name_shn,
      'name_en', candidate.name_en,
      'name_my', candidate.name_my,
      'is_active', candidate.is_active,
      'latitude', candidate.latitude,
      'longitude', candidate.longitude
    )
  else null end
  from (
    select c.*,
      6371 * 2 * asin(least(1, sqrt(
        power(sin(radians(c.latitude - p_latitude) / 2), 2) +
        cos(radians(p_latitude)) * cos(radians(c.latitude)) *
        power(sin(radians(c.longitude - p_longitude) / 2), 2)
      ))) as distance_km
    from public.cities c
    where c.is_active = true
      and c.latitude is not null
      and c.longitude is not null
      and p_latitude between -90 and 90
      and p_longitude between -180 and 180
    order by distance_km
    limit 1
  ) candidate;
$$;
revoke all on function public.resolve_city_for_coordinates(double precision, double precision)
from public;
grant execute on function public.resolve_city_for_coordinates(double precision, double precision)
to anon, authenticated, service_role;
commit;
