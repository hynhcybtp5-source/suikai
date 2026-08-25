begin;
-- Privacy is also enforced at rest, so authenticated public users cannot read
-- stale coordinates from an older client that only toggled the visibility flag.
update public.listings
set latitude = null, longitude = null
where is_location_visible = false
  and (latitude is not null or longitude is not null);
create or replace function public.clear_private_listing_coordinates()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.is_location_visible = false then
    new.latitude := null;
    new.longitude := null;
  end if;
  return new;
end;
$$;
drop trigger if exists clear_private_listing_coordinates on public.listings;
create trigger clear_private_listing_coordinates
before insert or update of is_location_visible, latitude, longitude
on public.listings
for each row execute function public.clear_private_listing_coordinates();
-- Anonymous clients read only these deliberately projected payloads. This is
-- required because RLS filters rows, not individual latitude/longitude fields.
create or replace function public.get_public_listings()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(payload order by created_at desc), '[]'::jsonb)
  from (
    select
      l.created_at,
      jsonb_build_object(
        'id', l.id,
        'store_id', l.store_id,
        'listing_type', l.listing_type,
        'title', l.title,
        'description', l.description,
        'category_id', l.category_id,
        'price', l.price,
        'currency', l.currency,
        'city', l.city,
        'city_id', l.city_id,
        'phone', l.phone,
        'viber_phone', l.viber_phone,
        'status', l.status,
        'latitude', case when l.is_location_visible then l.latitude else null end,
        'longitude', case when l.is_location_visible then l.longitude else null end,
        'is_location_visible', l.is_location_visible,
        'is_published', l.is_published,
        'is_hidden', false,
        'deleted_at', null,
        'created_at', l.created_at,
        'updated_at', l.updated_at,
        'listing_images', coalesce((
          select jsonb_agg(
            jsonb_build_object(
              'id', li.id,
              'image_url', li.image_url,
              'media_id', li.media_id,
              'sort_order', li.sort_order
            ) order by li.sort_order, li.created_at
          )
          from public.listing_images li
          where li.listing_id = l.id
        ), '[]'::jsonb),
        'cities', case when c.id is null then null else jsonb_build_object(
          'id', c.id,
          'name', c.name,
          'name_th', c.name_th,
          'name_shn', c.name_shn,
          'name_en', c.name_en,
          'name_my', c.name_my,
          'is_active', c.is_active
        ) end
      ) as payload
    from public.listings l
    left join public.cities c on c.id = l.city_id
    left join public.stores s on s.id = l.store_id
    where l.is_published = true
      and l.is_hidden = false
      and l.deleted_at is null
      and l.status in ('available', 'reserved')
      and (
        l.store_id is null
        or (
          s.status = 'approved'
          and s.lifecycle_status = 'active'
          and s.is_hidden = false
          and s.deleted_at is null
        )
      )
  ) public_rows;
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
  where s.status = 'approved'
    and s.lifecycle_status = 'active'
    and s.is_hidden = false
    and s.deleted_at is null;
$$;
revoke all on function public.get_public_listings() from public;
revoke all on function public.get_public_stores() from public;
grant execute on function public.get_public_listings() to anon, authenticated, service_role;
grant execute on function public.get_public_stores() to anon, authenticated, service_role;
-- Anonymous users must not bypass the sanitized projection with PostgREST.
revoke select on table public.listings from anon;
revoke select on table public.listing_images from anon;
revoke select on table public.stores from anon;
commit;
