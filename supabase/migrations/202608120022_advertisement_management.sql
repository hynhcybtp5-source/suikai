begin;
alter table public.banners
  add column if not exists target_type text,
  add column if not exists target_id uuid,
  add column if not exists external_url text,
  add column if not exists display_order integer,
  add column if not exists is_active boolean;
update public.banners
set target_type = coalesce(target_type, 'external'),
    external_url = coalesce(external_url, target_url),
    display_order = coalesce(display_order, sort_order, 0),
    is_active = coalesce(is_active, active, true);
alter table public.banners
  alter column target_type set default 'external',
  alter column target_type set not null,
  alter column display_order set default 0,
  alter column display_order set not null,
  alter column is_active set default true,
  alter column is_active set not null;
alter table public.banners drop constraint if exists banners_target_type_check;
alter table public.banners add constraint banners_target_type_check
  check (target_type in ('shop', 'product', 'category', 'external'));
create index if not exists banners_public_schedule_idx
on public.banners (is_active, start_at, end_at, display_order);
alter policy "public read current banners" on public.banners using (
  public.is_active_admin()
  or (
    is_active = true
    and (start_at is null or start_at <= now())
    and (end_at is null or end_at >= now())
  )
);
alter policy "admin manage banners" on public.banners
using (public.is_active_admin()) with check (public.is_active_admin());
insert into storage.buckets (id, name, public)
values ('banner-images', 'banner-images', true)
on conflict (id) do update set public = excluded.public;
create policy "public read banner images" on storage.objects for select
using (bucket_id = 'banner-images');
create policy "admins upload banner images" on storage.objects for insert
to authenticated with check (
  bucket_id = 'banner-images' and public.is_active_admin()
);
create policy "admins update banner images" on storage.objects for update
to authenticated using (
  bucket_id = 'banner-images' and public.is_active_admin()
) with check (
  bucket_id = 'banner-images' and public.is_active_admin()
);
create policy "admins delete banner images" on storage.objects for delete
to authenticated using (
  bucket_id = 'banner-images' and public.is_active_admin()
);
create policy "admins create banner media metadata"
on public.media_assets for insert to authenticated
with check (bucket = 'banner-images' and public.is_active_admin());
create policy "admins manage banner media metadata"
on public.media_assets for all to authenticated
using (bucket = 'banner-images' and public.is_active_admin())
with check (bucket = 'banner-images' and public.is_active_admin());
grant select on table public.banners to anon, authenticated;
grant insert, update, delete on table public.banners to authenticated;
commit;
