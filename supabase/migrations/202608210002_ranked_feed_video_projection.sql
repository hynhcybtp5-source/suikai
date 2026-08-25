begin;

-- The ranking projection intentionally stays small; this companion RPC restores
-- the private-media metadata needed by the existing signed-video playback flow.
create or replace function public.get_public_listing_videos(p_listing_ids uuid[])
returns jsonb language sql stable security definer set search_path = '' as $$
  select coalesce(jsonb_agg(jsonb_build_object(
    'listing_id', lv.listing_id, 'id', lv.id,
    'video_media_id', lv.video_media_id, 'thumbnail_media_id', lv.thumbnail_media_id,
    'duration_milliseconds', lv.duration_milliseconds, 'size_bytes', lv.size_bytes,
    'video_media_assets', jsonb_build_object('object_path', video.object_path),
    'thumbnail_media_assets', jsonb_build_object('object_path', thumb.object_path)
  )), '[]'::jsonb)
  from public.listing_videos lv
  join public.media_assets video on video.id = lv.video_media_id
  join public.media_assets thumb on thumb.id = lv.thumbnail_media_id
  where lv.listing_id = any(p_listing_ids) and public.is_listing_public(lv.listing_id);
$$;

revoke all on function public.get_public_listing_videos(uuid[]) from public;
grant execute on function public.get_public_listing_videos(uuid[]) to anon, authenticated, service_role;
commit;
