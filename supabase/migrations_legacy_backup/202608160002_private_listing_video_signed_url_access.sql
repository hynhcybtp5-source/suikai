begin;

-- Evaluated by Storage RLS when issuing a signed URL. SECURITY DEFINER is
-- required because anonymous public viewers must not receive SELECT access to
-- media_assets merely to prove an object belongs to a public listing.
create or replace function public.can_read_listing_video_object(
  p_bucket text,
  p_object_path text
)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    public.is_active_admin()
    or exists (
      select 1
      from public.listing_videos lv
      join public.listings l on l.id = lv.listing_id
      left join public.media_assets video_asset on video_asset.id = lv.video_media_id
      left join public.media_assets thumbnail_asset on thumbnail_asset.id = lv.thumbnail_media_id
      where l.owner_id = (select auth.uid())
        and (
          (p_bucket = 'listing-videos'
            and video_asset.bucket = p_bucket
            and video_asset.object_path = p_object_path)
          or
          (p_bucket = 'listing-thumbnails'
            and thumbnail_asset.bucket = p_bucket
            and thumbnail_asset.object_path = p_object_path)
        )
    )
    or exists (
      select 1
      from public.listing_videos lv
      join public.listings l on l.id = lv.listing_id
      left join public.media_assets video_asset on video_asset.id = lv.video_media_id
      left join public.media_assets thumbnail_asset on thumbnail_asset.id = lv.thumbnail_media_id
      where l.is_hidden = false
        and l.deleted_at is null
        and public.is_listing_public(l.id)
        and (
          (p_bucket = 'listing-videos'
            and video_asset.bucket = p_bucket
            and video_asset.object_path = p_object_path)
          or
          (p_bucket = 'listing-thumbnails'
            and thumbnail_asset.bucket = p_bucket
            and thumbnail_asset.object_path = p_object_path)
        )
    );
$$;

revoke all on function public.can_read_listing_video_object(text, text)
from public;
grant execute on function public.can_read_listing_video_object(text, text)
to anon, authenticated, service_role;

drop policy if exists "listing video object read by listing access"
on storage.objects;

create policy "listing video object read by listing access"
on storage.objects for select
using (
  bucket_id in ('listing-videos', 'listing-thumbnails')
  and public.can_read_listing_video_object(bucket_id, name)
);

commit;
