begin;

-- New posts use one compressed MP4 plus one generated thumbnail. Existing
-- listing_images rows remain untouched so legacy image listings continue to work.
create table public.listing_videos (
  id uuid primary key default gen_random_uuid(),
  listing_id uuid not null unique references public.listings(id) on delete cascade,
  video_media_id uuid not null unique references public.media_assets(id) on delete restrict,
  thumbnail_media_id uuid not null unique references public.media_assets(id) on delete restrict,
  duration_milliseconds integer not null check (
    duration_milliseconds > 0 and duration_milliseconds <= 30000
  ),
  size_bytes bigint not null check (size_bytes > 0 and size_bytes <= 5242880),
  created_at timestamptz not null default now(),
  constraint listing_video_distinct_assets check (video_media_id <> thumbnail_media_id)
);

create index listing_videos_listing_id_idx on public.listing_videos(listing_id);

alter table public.listing_videos enable row level security;

create policy "public read listing video metadata"
on public.listing_videos for select
using (
  public.is_listing_public(listing_id)
  or exists (
    select 1 from public.listings l
    where l.id = listing_id and l.owner_id = (select auth.uid())
  )
  or public.is_active_admin()
);

create policy "owners manage listing video metadata"
on public.listing_videos for all to authenticated
using (
  public.is_active_admin()
  or exists (
    select 1 from public.listings l
    where l.id = listing_id
      and l.owner_id = (select auth.uid())
      and public.is_active_user()
  )
)
with check (
  public.is_active_admin()
  or exists (
    select 1 from public.listings l
    where l.id = listing_id
      and l.owner_id = (select auth.uid())
      and public.is_active_user()
  )
);

revoke all on table public.listing_videos from public, anon, authenticated;
grant select, insert, update, delete on table public.listing_videos to authenticated;
grant all on table public.listing_videos to service_role;

insert into storage.buckets (id, name, public)
values
  ('listing-videos', 'listing-videos', false),
  ('listing-thumbnails', 'listing-thumbnails', false)
on conflict (id) do update set public = false;

-- Draft paths allow media to be uploaded before the listing row exists.
-- A referenced object can subsequently be read only while its listing is public,
-- or by that listing's owner/admin.
create policy "listing video object read by listing access"
on storage.objects for select
using (
  bucket_id in ('listing-videos', 'listing-thumbnails')
  and exists (
    select 1
    from public.listing_videos lv
    join public.listings l on l.id = lv.listing_id
    join public.media_assets ma on ma.id = case
      when bucket_id = 'listing-videos' then lv.video_media_id
      else lv.thumbnail_media_id
    end
    where ma.bucket = storage.objects.bucket_id
      and ma.object_path = storage.objects.name
      and l.is_hidden = false
      and l.deleted_at is null
      and (
        public.is_listing_public(l.id)
        or l.owner_id = (select auth.uid())
        or public.is_active_admin()
      )
  )
);

create policy "owners upload listing video drafts"
on storage.objects for insert to authenticated
with check (
  bucket_id in ('listing-videos', 'listing-thumbnails')
  and (storage.foldername(name))[1] = 'listings'
  and (storage.foldername(name))[2] = 'drafts'
  and (storage.foldername(name))[3] = (select auth.uid())::text
  and public.is_active_user()
);

create policy "owners delete listing video objects"
on storage.objects for delete to authenticated
using (
  bucket_id in ('listing-videos', 'listing-thumbnails')
  and (
    public.is_active_admin()
    or (
      (storage.foldername(name))[1] = 'listings'
      and (storage.foldername(name))[2] = 'drafts'
      and (storage.foldername(name))[3] = (select auth.uid())::text
      and public.is_active_user()
    )
    or exists (
      select 1 from public.listing_videos lv
      join public.listings l on l.id = lv.listing_id
      join public.media_assets ma on ma.id in (lv.video_media_id, lv.thumbnail_media_id)
      where ma.bucket = storage.objects.bucket_id
        and ma.object_path = storage.objects.name
        and l.owner_id = (select auth.uid())
        and public.is_active_user()
    )
  )
);

-- General posts may be published without a resolved city. Store products keep
-- their old invariant because their location is inherited from the store.
create or replace function public.require_listing_city_text()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.city := nullif(btrim(new.city), '');
  if new.listing_type = 'store' and new.city is null then
    raise exception using errcode = '23502', message = 'store listing city is required';
  end if;
  return new;
end;
$$;

create or replace function public.get_public_listings()
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select coalesce(jsonb_agg(payload order by created_at desc), '[]'::jsonb)
  from (
    select l.created_at, jsonb_build_object(
      'id', l.id, 'owner_id', l.owner_id, 'store_id', l.store_id,
      'listing_type', l.listing_type, 'title', l.title,
      'description', l.description, 'category_id', l.category_id,
      'price', l.price, 'currency', l.currency, 'city', l.city,
      'city_id', l.city_id, 'phone', l.phone, 'viber_phone', l.viber_phone,
      'status', l.status,
      'latitude', case when l.is_location_visible then l.latitude else null end,
      'longitude', case when l.is_location_visible then l.longitude else null end,
      'is_location_visible', l.is_location_visible, 'is_published', l.is_published,
      'is_hidden', false, 'deleted_at', null, 'created_at', l.created_at,
      'updated_at', l.updated_at,
      'listing_video', case when lv.id is null then null else jsonb_build_object(
        'id', lv.id, 'video_media_id', lv.video_media_id,
        'thumbnail_media_id', lv.thumbnail_media_id,
        'video_path', vm.object_path, 'thumbnail_path', tm.object_path,
        'duration_milliseconds', lv.duration_milliseconds, 'size_bytes', lv.size_bytes
      ) end,
      'listing_images', coalesce((
        select jsonb_agg(jsonb_build_object(
          'id', li.id, 'image_url', li.image_url, 'media_id', li.media_id,
          'sort_order', li.sort_order
        ) order by li.sort_order, li.created_at)
        from public.listing_images li where li.listing_id = l.id
      ), '[]'::jsonb),
      'cities', case when c.id is null then null else jsonb_build_object(
        'id', c.id, 'name', c.name, 'name_th', c.name_th, 'name_shn', c.name_shn,
        'name_en', c.name_en, 'name_my', c.name_my, 'is_active', c.is_active
      ) end
    ) payload
    from public.listings l
    left join public.cities c on c.id = l.city_id
    left join public.stores s on s.id = l.store_id
    left join public.listing_videos lv on lv.listing_id = l.id
    left join public.media_assets vm on vm.id = lv.video_media_id
    left join public.media_assets tm on tm.id = lv.thumbnail_media_id
    where l.is_published = true and l.is_hidden = false and l.deleted_at is null
      and l.status in ('available', 'reserved')
      and (l.store_id is null or (s.status = 'approved' and s.lifecycle_status = 'active'
        and s.is_hidden = false and s.deleted_at is null))
  ) public_rows;
$$;

commit;
