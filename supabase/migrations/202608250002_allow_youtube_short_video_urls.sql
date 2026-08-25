-- Keep the legacy table/column and all existing rows intact.  Legacy TikTok
-- URLs remain valid so admins can still hide, edit, or delete old entries.
-- New application validation accepts YouTube URLs only.
alter table public.tiktok_videos
  drop constraint if exists tiktok_videos_tiktok_url_check;

alter table public.tiktok_videos
  add constraint tiktok_videos_tiktok_url_check check (
    lower(tiktok_url) ~
      '^https://((youtube\.com|www\.youtube\.com|m\.youtube\.com|youtu\.be)|([a-z0-9-]+\.)*tiktok\.com)/'
  );
