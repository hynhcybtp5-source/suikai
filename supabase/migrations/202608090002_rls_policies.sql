begin;
alter table public.admin_profiles enable row level security;
alter table public.stores enable row level security;
alter table public.listings enable row level security;
alter table public.listing_images enable row level security;
alter table public.listing_likes enable row level security;
alter table public.listing_views enable row level security;
alter table public.reports enable row level security;
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1
    from public.admin_profiles
    where id = auth.uid()
  );
$$;
create policy "public read approved stores"
on public.stores
for select
using (
  status = 'approved'
  or owner_id = auth.uid()
  or public.is_admin()
);
create policy "authenticated create own store"
on public.stores
for insert
to authenticated
with check (
  owner_id = auth.uid()
);
create policy "owner update own store"
on public.stores
for update
to authenticated
using (
  owner_id = auth.uid()
  or public.is_admin()
)
with check (
  owner_id = auth.uid()
  or public.is_admin()
);
create policy "admin delete stores"
on public.stores
for delete
to authenticated
using (
  public.is_admin()
);
create policy "public read published listings"
on public.listings
for select
using (
  (
    is_published = true
    and status <> 'sold'
  )
  or owner_id = auth.uid()
  or public.is_admin()
);
create policy "authenticated create own listings"
on public.listings
for insert
to authenticated
with check (
  owner_id = auth.uid()
);
create policy "owner update own listings"
on public.listings
for update
to authenticated
using (
  owner_id = auth.uid()
  or public.is_admin()
)
with check (
  owner_id = auth.uid()
  or public.is_admin()
);
create policy "owner delete own listings"
on public.listings
for delete
to authenticated
using (
  owner_id = auth.uid()
  or public.is_admin()
);
create policy "public read listing images"
on public.listing_images
for select
using (
  exists (
    select 1
    from public.listings l
    where l.id = listing_id
      and (
        (l.is_published = true and l.status <> 'sold')
        or l.owner_id = auth.uid()
        or public.is_admin()
      )
  )
);
create policy "owner manage listing images"
on public.listing_images
for all
to authenticated
using (
  exists (
    select 1
    from public.listings l
    where l.id = listing_id
      and (
        l.owner_id = auth.uid()
        or public.is_admin()
      )
  )
)
with check (
  exists (
    select 1
    from public.listings l
    where l.id = listing_id
      and (
        l.owner_id = auth.uid()
        or public.is_admin()
      )
  )
);
create policy "public read likes"
on public.listing_likes
for select
using (true);
create policy "public create like"
on public.listing_likes
for insert
with check (
  length(trim(device_id)) > 0
);
create policy "public remove own device like"
on public.listing_likes
for delete
using (
  length(trim(device_id)) > 0
);
create policy "public read views"
on public.listing_views
for select
using (true);
create policy "public create views"
on public.listing_views
for insert
with check (true);
create policy "public create reports"
on public.reports
for insert
with check (
  status = 'open'
  and reviewed_by is null
  and reviewed_at is null
);
create policy "admin read reports"
on public.reports
for select
to authenticated
using (
  public.is_admin()
);
create policy "admin update reports"
on public.reports
for update
to authenticated
using (
  public.is_admin()
)
with check (
  public.is_admin()
);
create policy "admin delete reports"
on public.reports
for delete
to authenticated
using (
  public.is_admin()
);
create policy "admin read admin profiles"
on public.admin_profiles
for select
to authenticated
using (
  id = auth.uid()
  or public.is_admin()
);
create policy "admin manage admin profiles"
on public.admin_profiles
for all
to authenticated
using (
  public.is_admin()
)
with check (
  public.is_admin()
);
commit;
