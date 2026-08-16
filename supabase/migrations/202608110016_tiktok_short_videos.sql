begin;

create table public.tiktok_videos (
  id uuid primary key default gen_random_uuid(),
  tiktok_url text not null check (
    lower(tiktok_url) ~ '^https://([a-z0-9-]+\.)*tiktok\.com/'
  ),
  title text,
  sort_order integer not null default 0,
  is_active boolean not null default true,
  created_by uuid references auth.users(id) on delete set null,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index tiktok_videos_is_active_idx
on public.tiktok_videos (is_active);

create index tiktok_videos_sort_order_idx
on public.tiktok_videos (sort_order);

create trigger tiktok_videos_set_updated_at
before update on public.tiktok_videos
for each row execute function public.set_updated_at();

alter table public.tiktok_videos enable row level security;

create policy "public read active tiktok videos"
on public.tiktok_videos
for select
to anon, authenticated
using (is_active = true);

create policy "admins read all tiktok videos"
on public.tiktok_videos
for select
to authenticated
using (public.is_active_admin());

create policy "admins create tiktok videos"
on public.tiktok_videos
for insert
to authenticated
with check (
  public.is_active_admin()
  and created_by = (select auth.uid())
);

create policy "admins update tiktok videos"
on public.tiktok_videos
for update
to authenticated
using (public.is_active_admin())
with check (public.is_active_admin());

create policy "admins delete tiktok videos"
on public.tiktok_videos
for delete
to authenticated
using (public.is_active_admin());

revoke all on table public.tiktok_videos from public, anon, authenticated;
grant select on table public.tiktok_videos to anon, authenticated;
grant insert, update, delete on table public.tiktok_videos to authenticated;
grant all on table public.tiktok_videos to service_role;

commit;
