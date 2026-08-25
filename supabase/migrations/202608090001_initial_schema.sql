begin;
create extension if not exists "pgcrypto";
create type public.listing_type as enum (
  'general',
  'store'
);
create type public.listing_status as enum (
  'available',
  'reserved',
  'sold',
  'out_of_stock'
);
create type public.store_status as enum (
  'pending',
  'approved',
  'rejected',
  'suspended'
);
create type public.report_status as enum (
  'open',
  'reviewing',
  'resolved',
  'dismissed'
);
create table public.admin_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  display_name text,
  phone text,
  created_at timestamptz not null default now()
);
create table public.stores (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid not null references auth.users(id) on delete cascade,
  name text not null,
  description text,
  logo_url text,

  category text,

  phone text,
  viber_phone text,

  city text,
  latitude double precision,
  longitude double precision,

  opening_time time,
  closing_time time,

  status public.store_status not null default 'pending',

  approved_by uuid references auth.users(id),
  approved_at timestamptz,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.listings (
  id uuid primary key default gen_random_uuid(),

  owner_id uuid references auth.users(id) on delete set null,
  store_id uuid references public.stores(id) on delete cascade,

  listing_type public.listing_type not null default 'general',

  title text not null,
  description text,

  category text,

  price numeric(18,2),
  currency text not null default 'MMK',

  city text,

  phone text,
  viber_phone text,

  status public.listing_status not null default 'available',

  is_published boolean not null default true,

  published_at timestamptz default now(),

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),

  constraint listings_store_rule check (
    (listing_type = 'general' and store_id is null)
    or
    (listing_type = 'store' and store_id is not null)
  )
);
create table public.listing_images (
  id uuid primary key default gen_random_uuid(),

  listing_id uuid not null
    references public.listings(id)
    on delete cascade,

  image_url text not null,

  sort_order integer not null default 0,

  created_at timestamptz not null default now()
);
create table public.listing_likes (
  id uuid primary key default gen_random_uuid(),

  listing_id uuid not null
    references public.listings(id)
    on delete cascade,

  device_id text not null,

  created_at timestamptz not null default now(),

  unique (listing_id, device_id)
);
create table public.listing_views (
  id uuid primary key default gen_random_uuid(),

  listing_id uuid not null
    references public.listings(id)
    on delete cascade,

  device_id text,

  created_at timestamptz not null default now()
);
create table public.reports (
  id uuid primary key default gen_random_uuid(),

  listing_id uuid
    references public.listings(id)
    on delete cascade,

  store_id uuid
    references public.stores(id)
    on delete cascade,

  device_id text,

  reason text not null,
  details text,

  status public.report_status not null default 'open',

  reviewed_by uuid references auth.users(id),
  reviewed_at timestamptz,

  created_at timestamptz not null default now(),

  constraint report_target check (
    listing_id is not null
    or store_id is not null
  )
);
create index idx_stores_owner_id
  on public.stores(owner_id);
create index idx_stores_status
  on public.stores(status);
create index idx_stores_city
  on public.stores(city);
create index idx_listings_owner_id
  on public.listings(owner_id);
create index idx_listings_store_id
  on public.listings(store_id);
create index idx_listings_type
  on public.listings(listing_type);
create index idx_listings_status
  on public.listings(status);
create index idx_listings_city
  on public.listings(city);
create index idx_listings_price
  on public.listings(price);
create index idx_listing_images_listing_id
  on public.listing_images(listing_id);
create index idx_listing_likes_listing_id
  on public.listing_likes(listing_id);
create index idx_listing_views_listing_id
  on public.listing_views(listing_id);
create index idx_reports_status
  on public.reports(status);
create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;
create trigger stores_set_updated_at
before update on public.stores
for each row
execute function public.set_updated_at();
create trigger listings_set_updated_at
before update on public.listings
for each row
execute function public.set_updated_at();
create or replace function public.enforce_store_listing_publish()
returns trigger
language plpgsql
as $$
declare
  current_store_status public.store_status;
begin
  if new.listing_type = 'store' then

    select status
    into current_store_status
    from public.stores
    where id = new.store_id;

    if current_store_status is distinct from 'approved' then
      new.is_published := false;
      new.published_at := null;
    end if;

  else
    new.is_published := true;

    if new.published_at is null then
      new.published_at := now();
    end if;
  end if;

  return new;
end;
$$;
create trigger listings_publish_rules
before insert or update
on public.listings
for each row
execute function public.enforce_store_listing_publish();
create or replace view public.listing_stats
as
select
  l.id as listing_id,

  count(distinct lk.id) as like_count,

  count(distinct vw.id) as view_count

from public.listings l

left join public.listing_likes lk
  on lk.listing_id = l.id

left join public.listing_views vw
  on vw.listing_id = l.id

group by l.id;
commit;
