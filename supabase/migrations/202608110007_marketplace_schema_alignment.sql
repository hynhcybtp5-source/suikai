begin;
-- Marketplace media metadata. Existing URL columns remain available during
-- repository migration; no local or remote media is rewritten here.
create table public.media_assets (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles(id) on delete set null,
  bucket text not null check (length(btrim(bucket)) > 0),
  object_path text not null check (length(btrim(object_path)) > 0),
  mime_type text,
  size_bytes bigint check (size_bytes is null or size_bytes >= 0),
  width integer check (width is null or width > 0),
  height integer check (height is null or height > 0),
  checksum text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (bucket, object_path)
);
-- Align the legacy category table with CategoryRecord without removing its
-- original columns. legacy_key preserves Hive slug IDs such as store_food.
alter table public.categories
  add column type public.category_type,
  add column legacy_key text,
  add column name_th text,
  add column name_shn text,
  add column name_en text,
  add column name_my text,
  add column is_active boolean,
  add column updated_at timestamptz not null default now();
update public.categories
set
  type = kind::public.category_type,
  name_th = name,
  name_shn = name,
  name_en = name,
  name_my = name,
  is_active = active
where type is null;
alter table public.categories
  alter column type set not null,
  alter column is_active set default true,
  alter column is_active set not null,
  alter column name_th set not null,
  alter column name_shn set not null,
  alter column name_en set not null,
  alter column name_my set not null;
create unique index categories_legacy_key_unique
on public.categories (legacy_key)
where legacy_key is not null;
create index categories_type_active_order_idx
on public.categories (type, is_active, sort_order);
create or replace function public.sync_category_legacy_fields()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if tg_op = 'INSERT' then
    if new.type is null then
      new.type := new.kind::public.category_type;
      new.name_th := coalesce(new.name_th, new.name);
      new.name_shn := coalesce(new.name_shn, new.name);
      new.name_en := coalesce(new.name_en, new.name);
      new.name_my := coalesce(new.name_my, new.name);
      new.is_active := new.active;
    else
      new.kind := new.type::text;
      new.name := new.name_th;
      new.active := new.is_active;
    end if;
  else
    if new.type is distinct from old.type then
      new.kind := new.type::text;
    elsif new.kind is distinct from old.kind then
      new.type := new.kind::public.category_type;
    end if;

    if new.name_th is distinct from old.name_th then
      new.name := new.name_th;
    elsif new.name is distinct from old.name then
      new.name_th := new.name;
    end if;

    if new.is_active is distinct from old.is_active then
      new.active := new.is_active;
    elsif new.active is distinct from old.active then
      new.is_active := new.active;
    end if;
  end if;

  return new;
end;
$$;
create trigger categories_sync_legacy_fields
before insert or update on public.categories
for each row execute function public.sync_category_legacy_fields();
create trigger categories_set_updated_at
before update on public.categories
for each row execute function public.set_updated_at();
-- Store rows continue to represent store applications while pending. The new
-- lifecycle column maps legacy approved to canonical active without deletion.
alter table public.stores
  add column lifecycle_status public.canonical_store_status,
  add column category_id uuid references public.categories(id),
  add column location text,
  add column is_hidden boolean not null default false,
  add column deleted_at timestamptz,
  add column is_promoted boolean not null default false,
  add column promotion_start_at timestamptz,
  add column promotion_end_at timestamptz,
  add column logo_media_id uuid references public.media_assets(id) on delete set null,
  add column cover_media_id uuid references public.media_assets(id) on delete set null;
update public.stores
set lifecycle_status = case status
  when 'approved' then 'active'::public.canonical_store_status
  when 'suspended' then 'suspended'::public.canonical_store_status
  when 'rejected' then 'rejected'::public.canonical_store_status
  else 'pending'::public.canonical_store_status
end
where lifecycle_status is null;
alter table public.stores
  alter column lifecycle_status set default 'pending',
  alter column lifecycle_status set not null;
alter table public.stores
  add constraint stores_lifecycle_status_consistency check (
    (status = 'pending' and lifecycle_status = 'pending')
    or (status = 'approved' and lifecycle_status = 'active')
    or (status = 'suspended' and lifecycle_status = 'suspended')
    or (status = 'rejected' and lifecycle_status = 'rejected')
  ) not valid,
  add constraint stores_promotion_dates_valid check (
    promotion_start_at is null
    or promotion_end_at is null
    or promotion_end_at >= promotion_start_at
  ) not valid,
  add constraint stores_latitude_valid check (
    latitude is null or latitude between -90 and 90
  ) not valid,
  add constraint stores_longitude_valid check (
    longitude is null or longitude between -180 and 180
  ) not valid;
create index stores_lifecycle_public_idx
on public.stores (lifecycle_status, is_hidden, deleted_at);
create index stores_category_id_idx on public.stores (category_id);
create index stores_promoted_idx
on public.stores (is_promoted, promotion_start_at, promotion_end_at)
where is_promoted = true;
-- The legacy listing_status enum is intentionally retained because it already
-- contains both general listing and store-product values.
alter table public.listings
  add column category_id uuid references public.categories(id),
  add column location text,
  add column latitude double precision,
  add column longitude double precision,
  add column is_location_visible boolean not null default true,
  add column is_hidden boolean not null default false,
  add column deleted_at timestamptz;
alter table public.listings
  add constraint listings_owner_required check (owner_id is not null) not valid,
  add constraint listings_price_nonnegative check (
    price is null or price >= 0
  ) not valid,
  add constraint listings_latitude_valid check (
    latitude is null or latitude between -90 and 90
  ) not valid,
  add constraint listings_longitude_valid check (
    longitude is null or longitude between -180 and 180
  ) not valid,
  add constraint listings_status_by_type check (
    (
      listing_type = 'general'
      and status in ('available', 'reserved', 'sold')
    )
    or
    (
      listing_type = 'store'
      and status in ('available', 'out_of_stock', 'deleted')
    )
  ) not valid;
create index listings_public_feed_idx
on public.listings (listing_type, status, is_published, is_hidden, created_at desc);
create index listings_category_id_idx on public.listings (category_id);
create index listings_location_idx on public.listings (city, latitude, longitude);
alter table public.listing_images
  add column media_id uuid references public.media_assets(id) on delete set null,
  add column is_primary boolean not null default false,
  add column alt_text text;
alter table public.listing_images
  add constraint listing_images_sort_order_nonnegative check (sort_order >= 0) not valid;
create unique index listing_images_media_unique
on public.listing_images (listing_id, media_id)
where media_id is not null;
create index listing_images_order_idx
on public.listing_images (listing_id, sort_order);
-- Future views use a server-generated hash in view_key. Existing rows remain
-- untouched and therefore do not block the partial unique index.
alter table public.listing_views add column view_key text;
create unique index listing_views_device_unique
on public.listing_views (listing_id, view_key)
where view_key is not null;
alter table public.listing_likes
  add column user_id uuid references public.profiles(id) on delete set null;
-- Add canonical report workflow without rewriting the legacy status column.
alter table public.reports
  add column reporter_id uuid references public.profiles(id) on delete set null,
  add column reporter_device_hash text,
  add column workflow_status public.canonical_report_status,
  add column resolution_note text,
  add column updated_at timestamptz not null default now();
update public.reports
set workflow_status = case status
  when 'reviewing' then 'reviewed'::public.canonical_report_status
  when 'resolved' then 'resolved'::public.canonical_report_status
  when 'dismissed' then 'rejected'::public.canonical_report_status
  else 'pending'::public.canonical_report_status
end
where workflow_status is null;
alter table public.reports
  alter column workflow_status set default 'pending',
  alter column workflow_status set not null,
  add constraint reports_exactly_one_target check (
    (listing_id is not null) <> (store_id is not null)
  ) not valid;
create index reports_workflow_status_idx
on public.reports (workflow_status, created_at desc);
create trigger reports_set_updated_at
before update on public.reports
for each row execute function public.set_updated_at();
create table public.store_edit_requests (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete restrict,
  owner_id uuid not null references public.profiles(id) on delete restrict,
  before_snapshot jsonb not null default '{}'::jsonb
    check (jsonb_typeof(before_snapshot) = 'object'),
  proposed_changes jsonb not null
    check (jsonb_typeof(proposed_changes) = 'object'),
  status public.request_status not null default 'pending',
  reviewed_by uuid references public.admin_roles(user_id) on delete set null,
  review_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  reviewed_at timestamptz
);
create unique index store_edit_requests_one_pending_idx
on public.store_edit_requests (store_id)
where status = 'pending';
create index store_edit_requests_owner_idx
on public.store_edit_requests (owner_id, created_at desc);
create index store_edit_requests_status_idx
on public.store_edit_requests (status, created_at desc);
create trigger store_edit_requests_set_updated_at
before update on public.store_edit_requests
for each row execute function public.set_updated_at();
create table public.promotion_requests (
  id uuid primary key default gen_random_uuid(),
  store_id uuid not null references public.stores(id) on delete restrict,
  owner_id uuid not null references public.profiles(id) on delete restrict,
  requested_start_at timestamptz,
  requested_end_at timestamptz,
  status public.promotion_status not null default 'pending',
  reviewed_by uuid references public.admin_roles(user_id) on delete set null,
  review_note text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  reviewed_at timestamptz,
  check (
    requested_start_at is null
    or requested_end_at is null
    or requested_end_at >= requested_start_at
  )
);
create unique index promotion_requests_one_pending_idx
on public.promotion_requests (store_id)
where status = 'pending';
create index promotion_requests_owner_idx
on public.promotion_requests (owner_id, created_at desc);
create index promotion_requests_status_idx
on public.promotion_requests (status, created_at desc);
create trigger promotion_requests_set_updated_at
before update on public.promotion_requests
for each row execute function public.set_updated_at();
create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  recipient_id uuid not null references public.profiles(id) on delete cascade,
  event_type text not null check (length(btrim(event_type)) > 0),
  payload jsonb not null default '{}'::jsonb
    check (jsonb_typeof(payload) = 'object'),
  is_read boolean not null default false,
  read_at timestamptz,
  created_at timestamptz not null default now(),
  check ((is_read = false and read_at is null) or is_read = true)
);
create index notifications_recipient_idx
on public.notifications (recipient_id, is_read, created_at desc);
create table public.admin_audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.admin_roles(user_id) on delete set null,
  action text not null check (length(btrim(action)) > 0),
  target_type text not null check (length(btrim(target_type)) > 0),
  target_id text,
  before_data jsonb,
  after_data jsonb,
  created_at timestamptz not null default now()
);
create index admin_audit_logs_actor_idx
on public.admin_audit_logs (actor_id, created_at desc);
create index admin_audit_logs_target_idx
on public.admin_audit_logs (target_type, target_id, created_at desc);
alter table public.profiles
  add constraint profiles_avatar_media_id_fk
  foreign key (avatar_media_id) references public.media_assets(id)
  on delete set null not valid;
create trigger media_assets_set_updated_at
before update on public.media_assets
for each row execute function public.set_updated_at();
commit;
