-- Suikai clean-start baseline.  Apply only to an empty Supabase project.
-- This file intentionally does not migrate, alter, or delete the legacy project.
begin;

create extension if not exists pgcrypto;

create type public.profile_status as enum ('active', 'suspended');
create type public.store_status as enum ('pending', 'approved', 'rejected', 'suspended');
create type public.listing_status as enum ('available', 'reserved', 'sold');
create type public.listing_type as enum ('general', 'store');
create type public.request_status as enum ('pending', 'approved', 'rejected');
create type public.promotion_status as enum ('pending', 'approved', 'rejected', 'expired');
create type public.report_status as enum ('pending', 'reviewed', 'resolved', 'rejected');
create type public.category_type as enum ('store', 'listing');

create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  phone text,
  viber_phone text,
  email text,
  city text,
  city_id uuid,
  avatar_media_id uuid,
  status public.profile_status not null default 'active',
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.admin_roles (
  user_id uuid primary key references public.profiles(id) on delete cascade,
  role text not null check (role = 'admin'), is_active boolean not null default true,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  created_by uuid references public.profiles(id) on delete set null
);
create table public.categories (
  id uuid primary key default gen_random_uuid(), type public.category_type not null,
  name_th text not null, name_shn text not null, name_en text not null, name_my text not null,
  icon_key text not null default 'category', is_active boolean not null default true,
  sort_order integer not null default 0 check (sort_order >= 0),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.cities (
  id uuid primary key default gen_random_uuid(), name text not null unique,
  name_th text not null default '', name_shn text not null default '', name_en text not null default '', name_my text not null default '',
  is_active boolean not null default true, latitude double precision, longitude double precision,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check ((latitude is null and longitude is null) or (latitude between -90 and 90 and longitude between -180 and 180))
);
alter table public.profiles add constraint profiles_city_id_fkey foreign key (city_id) references public.cities(id) on delete set null;

create table public.media_assets (
  id uuid primary key default gen_random_uuid(), owner_id uuid references public.profiles(id) on delete set null,
  bucket text not null, object_path text not null, mime_type text, size_bytes bigint check (size_bytes is null or size_bytes >= 0),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(), unique(bucket, object_path)
);
alter table public.profiles add constraint profiles_avatar_media_id_fkey foreign key (avatar_media_id) references public.media_assets(id) on delete set null;

create table public.stores (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id) on delete cascade,
  name text not null, description text, category_id uuid references public.categories(id),
  logo_media_id uuid references public.media_assets(id) on delete set null, cover_media_id uuid references public.media_assets(id) on delete set null,
  phone text, viber_phone text, email text, city text, city_id uuid references public.cities(id) on delete set null,
  location text, latitude double precision, longitude double precision, opening_time time, closing_time time,
  status public.store_status not null default 'pending', rejection_reason text,
  is_hidden boolean not null default false, deleted_at timestamptz,
  is_promoted boolean not null default false, promotion_start_at timestamptz, promotion_end_at timestamptz,
  approved_by uuid references public.profiles(id) on delete set null, approved_at timestamptz,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check ((latitude is null and longitude is null) or (latitude between -90 and 90 and longitude between -180 and 180)),
  check (phone is not null or viber_phone is not null),
  check (promotion_end_at is null or promotion_start_at is null or promotion_end_at >= promotion_start_at)
);

create table public.listings (
  id uuid primary key default gen_random_uuid(), owner_id uuid not null references public.profiles(id) on delete cascade,
  store_id uuid references public.stores(id) on delete cascade, listing_type public.listing_type not null default 'general',
  title text not null, description text, category_id uuid references public.categories(id), price numeric(18,2) not null check(price >= 0),
  currency text not null default 'MMK', city text, city_id uuid references public.cities(id) on delete set null, location text,
  latitude double precision, longitude double precision, is_location_visible boolean not null default true,
  status public.listing_status not null default 'available', is_hidden boolean not null default false, deleted_at timestamptz,
  is_video_ready boolean not null default false,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check ((listing_type = 'general' and store_id is null) or (listing_type = 'store' and store_id is not null)),
  check ((latitude is null and longitude is null) or (latitude between -90 and 90 and longitude between -180 and 180))
);
create table public.listing_videos (
  id uuid primary key default gen_random_uuid(), listing_id uuid not null unique references public.listings(id) on delete cascade,
  video_media_id uuid not null unique references public.media_assets(id) on delete restrict,
  thumbnail_media_id uuid not null unique references public.media_assets(id) on delete restrict,
  duration_milliseconds integer not null check(duration_milliseconds > 0 and duration_milliseconds <= 30000),
  size_bytes bigint not null check(size_bytes > 0 and size_bytes <= 5242880), created_at timestamptz not null default now(),
  check(video_media_id <> thumbnail_media_id)
);
create table public.listing_likes (
  id uuid primary key default gen_random_uuid(), listing_id uuid not null references public.listings(id) on delete cascade,
  device_hash text not null, user_id uuid references public.profiles(id) on delete set null, created_at timestamptz not null default now(), unique(listing_id, device_hash)
);
create table public.listing_views (
  id uuid primary key default gen_random_uuid(), listing_id uuid not null references public.listings(id) on delete cascade,
  view_hash text not null, created_at timestamptz not null default now(), unique(listing_id, view_hash)
);
create table public.reports (
  id uuid primary key default gen_random_uuid(), listing_id uuid references public.listings(id) on delete cascade,
  store_id uuid references public.stores(id) on delete cascade, reporter_id uuid references public.profiles(id) on delete set null,
  reporter_device_hash text, reason text not null, details text, status public.report_status not null default 'pending',
  reviewed_by uuid references public.profiles(id) on delete set null, reviewed_at timestamptz, resolution_note text,
  created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check ((listing_id is not null) <> (store_id is not null))
);
create table public.notifications (
  id uuid primary key default gen_random_uuid(), recipient_id uuid not null references public.profiles(id) on delete cascade,
  event_type text not null check(length(btrim(event_type)) > 0), payload jsonb not null default '{}'::jsonb,
  is_read boolean not null default false, read_at timestamptz, created_at timestamptz not null default now()
);
create table public.admin_notifications (
  id uuid primary key default gen_random_uuid(), type text not null, shop_id uuid references public.stores(id) on delete cascade,
  listing_id uuid references public.listings(id) on delete cascade, title text not null, message text, is_read boolean not null default false,
  created_at timestamptz not null default now(), check(shop_id is not null or listing_id is not null)
);
create table public.store_edit_requests (
  id uuid primary key default gen_random_uuid(), store_id uuid not null references public.stores(id) on delete restrict,
  owner_id uuid not null references public.profiles(id) on delete restrict, before_snapshot jsonb not null default '{}'::jsonb,
  proposed_changes jsonb not null, status public.request_status not null default 'pending', reviewed_by uuid references public.profiles(id) on delete set null,
  review_note text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), reviewed_at timestamptz
);
create table public.promotion_requests (
  id uuid primary key default gen_random_uuid(), store_id uuid not null references public.stores(id) on delete restrict,
  owner_id uuid not null references public.profiles(id) on delete restrict, requested_start_at timestamptz, requested_end_at timestamptz,
  status public.promotion_status not null default 'pending', reviewed_by uuid references public.profiles(id) on delete set null,
  review_note text, created_at timestamptz not null default now(), updated_at timestamptz not null default now(), reviewed_at timestamptz,
  check(requested_end_at is null or requested_start_at is null or requested_end_at >= requested_start_at)
);
create table public.tiktok_videos (
  id uuid primary key default gen_random_uuid(), title text not null default '', tiktok_url text not null,
  is_active boolean not null default true, display_order integer not null default 0 check(display_order >= 0),
  created_at timestamptz not null default now(), updated_at timestamptz not null default now()
);
create table public.banners (
  id uuid primary key default gen_random_uuid(), title text not null, image_url text not null, media_id uuid references public.media_assets(id) on delete set null,
  target_url text, target_type text not null default 'external' check(target_type in ('shop','product','category','external')),
  target_id text, placement text not null default 'home', is_active boolean not null default true, display_order integer not null default 0,
  start_at timestamptz, end_at timestamptz, created_at timestamptz not null default now(), updated_at timestamptz not null default now(),
  check(end_at is null or start_at is null or end_at >= start_at)
);

create index listings_public_idx on public.listings(status, is_video_ready, created_at desc) where is_hidden = false and deleted_at is null;
create index listings_store_idx on public.listings(store_id, created_at desc); create index listings_category_idx on public.listings(category_id);
create index stores_public_idx on public.stores(status, created_at desc) where is_hidden = false and deleted_at is null;
create index listing_likes_listing_idx on public.listing_likes(listing_id); create index listing_views_listing_idx on public.listing_views(listing_id);
create index reports_status_idx on public.reports(status, created_at desc); create index notifications_recipient_idx on public.notifications(recipient_id,is_read,created_at desc);
create index admin_notifications_unread_idx on public.admin_notifications(is_read,created_at desc);
create unique index admin_notifications_shop_unique on public.admin_notifications(shop_id,type) where shop_id is not null and type='shop_application';
create unique index admin_notifications_listing_unique on public.admin_notifications(listing_id,type) where listing_id is not null and type='new_listing';
create unique index store_edit_one_pending on public.store_edit_requests(store_id) where status='pending';
create unique index promotion_one_pending on public.promotion_requests(store_id) where status='pending';
create index categories_public_idx on public.categories(type,is_active,sort_order);

create or replace function public.set_updated_at() returns trigger language plpgsql set search_path='' as $$ begin new.updated_at=now(); return new; end; $$;
create or replace function public.is_active_admin() returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.admin_roles r join public.profiles p on p.id=r.user_id where r.user_id=(select auth.uid()) and r.is_active and p.status='active'); $$;
create or replace function public.is_active_user() returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.profiles where id=(select auth.uid()) and status='active'); $$;
create or replace function public.is_listing_public(p_listing_id uuid) returns boolean language sql stable security definer set search_path='' as $$
  select exists(select 1 from public.listings l left join public.stores s on s.id=l.store_id where l.id=p_listing_id and l.status in ('available','reserved') and l.is_video_ready and not l.is_hidden and l.deleted_at is null and (l.listing_type='general' or (s.status='approved' and not s.is_hidden and s.deleted_at is null))); $$;
create or replace function public.handle_new_auth_user_profile() returns trigger language plpgsql security definer set search_path='' as $$
begin insert into public.profiles(id,name,phone,email,city) values(new.id,nullif(btrim(coalesce(new.raw_user_meta_data->>'name',new.raw_user_meta_data->>'full_name','')),''),nullif(btrim(coalesce(new.phone,new.raw_user_meta_data->>'phone','')),''),nullif(lower(btrim(coalesce(new.email,''))),''),nullif(btrim(coalesce(new.raw_user_meta_data->>'city','')),'')) on conflict(id) do nothing; return new; end; $$;
create or replace function public.sync_current_profile_from_auth() returns void language plpgsql security definer set search_path='' as $$ begin
  insert into public.profiles(id,name,phone,email,city)
  select u.id,nullif(btrim(coalesce(u.raw_user_meta_data->>'name',u.raw_user_meta_data->>'full_name','')),''),nullif(btrim(coalesce(u.phone,u.raw_user_meta_data->>'phone','')),''),nullif(lower(btrim(coalesce(u.email,''))),''),nullif(btrim(coalesce(u.raw_user_meta_data->>'city','')), '')
  from auth.users u where u.id=auth.uid() on conflict(id) do nothing;
end; $$;
-- A listing can be inserted while video metadata is uploaded. It becomes public only after this trigger marks it ready.
create or replace function public.mark_listing_video_ready() returns trigger language plpgsql security definer set search_path='' as $$ begin update public.listings set is_video_ready=true where id=new.listing_id; return new; end; $$;
create or replace function public.clear_listing_video_ready() returns trigger language plpgsql security definer set search_path='' as $$ begin update public.listings set is_video_ready=false where id=old.listing_id; return old; end; $$;
create or replace function public.enforce_store_listing_owner() returns trigger language plpgsql security definer set search_path='' as $$ begin
 if new.listing_type='store' and not exists(select 1 from public.stores where id=new.store_id and owner_id=new.owner_id and status='approved' and not is_hidden and deleted_at is null) then raise exception 'store_not_approved_or_not_owned'; end if; return new; end; $$;
create or replace function public.notify_listing_owner_on_like() returns trigger language plpgsql security definer set search_path='' as $$ begin
 insert into public.notifications(recipient_id,event_type,payload) select owner_id,'listing_liked',jsonb_build_object('listing_id',id,'listing_title',title) from public.listings where id=new.listing_id and owner_id is distinct from new.user_id; return new; end; $$;
create or replace function public.notify_admin_on_store() returns trigger language plpgsql security definer set search_path='' as $$ begin
 insert into public.admin_notifications(type,shop_id,title,message) values('shop_application',new.id,'คำขอเปิดร้านใหม่','ร้าน '||new.name||' ส่งคำขอเปิดร้าน') on conflict do nothing; return new; end; $$;
create or replace function public.notify_admin_on_listing() returns trigger language plpgsql security definer set search_path='' as $$ begin
 insert into public.admin_notifications(type,listing_id,title,message) values('new_listing',new.id,'ประกาศใหม่',new.title) on conflict do nothing; return new; end; $$;

create or replace function public.get_listing_like_count(p_listing_id uuid) returns integer language sql stable security definer set search_path='' as $$ select count(*)::integer from public.listing_likes where listing_id=p_listing_id; $$;
create or replace function public.get_listing_view_count(p_listing_id uuid) returns integer language sql stable security definer set search_path='' as $$ select count(*)::integer from public.listing_views where listing_id=p_listing_id; $$;
create or replace function public.toggle_listing_like(p_listing_id uuid,p_device_id text) returns boolean language plpgsql security definer set search_path='' as $$ declare h text:=encode(digest(btrim(p_device_id),'sha256'),'hex'); begin
 if btrim(coalesce(p_device_id,''))='' or not public.is_listing_public(p_listing_id) then raise exception 'listing_not_public_or_device_missing'; end if;
 if exists(select 1 from public.listing_likes where listing_id=p_listing_id and device_hash=h) then delete from public.listing_likes where listing_id=p_listing_id and device_hash=h; return false; end if;
 insert into public.listing_likes(listing_id,device_hash,user_id) values(p_listing_id,h,auth.uid()); return true; end; $$;
create or replace function public.record_listing_view(p_listing_id uuid,p_device_id text) returns boolean language plpgsql security definer set search_path='' as $$ declare h text:=encode(digest(btrim(p_device_id),'sha256'),'hex'); begin
 if btrim(coalesce(p_device_id,''))='' or not public.is_listing_public(p_listing_id) then return false; end if; insert into public.listing_views(listing_id,view_hash) values(p_listing_id,h) on conflict do nothing; return true; end; $$;
create or replace function public.resolve_city_for_coordinates(p_latitude double precision,p_longitude double precision) returns jsonb language sql stable security definer set search_path='' as $$
 select case when c.distance_km<=100 then jsonb_build_object('id',c.id,'name',c.name,'name_th',c.name_th,'name_shn',c.name_shn,'name_en',c.name_en,'name_my',c.name_my,'is_active',c.is_active,'latitude',c.latitude,'longitude',c.longitude) end from (select *,6371*2*asin(least(1,sqrt(power(sin(radians(latitude-p_latitude)/2),2)+cos(radians(p_latitude))*cos(radians(latitude))*power(sin(radians(longitude-p_longitude)/2),2)))) distance_km from public.cities where is_active and latitude is not null and longitude is not null and p_latitude between -90 and 90 and p_longitude between -180 and 180 order by distance_km limit 1) c; $$;
create or replace function public.get_public_listings() returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object('id',l.id,'owner_id',l.owner_id,'store_id',l.store_id,'listing_type',l.listing_type,'title',l.title,'description',l.description,'category_id',l.category_id,'price',l.price,'currency',l.currency,'city',l.city,'city_id',l.city_id,'location',l.location,'phone',coalesce(s.phone,p.phone),'viber_phone',coalesce(s.viber_phone,p.viber_phone),'latitude',case when l.is_location_visible then l.latitude end,'longitude',case when l.is_location_visible then l.longitude end,'is_location_visible',l.is_location_visible,'status',l.status,'created_at',l.created_at,'updated_at',l.updated_at,'listing_video',jsonb_build_object('id',v.id,'video_media_id',v.video_media_id,'thumbnail_media_id',v.thumbnail_media_id,'video_path',vm.object_path,'thumbnail_path',tm.object_path,'duration_milliseconds',v.duration_milliseconds,'size_bytes',v.size_bytes),'cities',case when c.id is null then null else jsonb_build_object('id',c.id,'name',c.name,'name_th',c.name_th,'name_shn',c.name_shn,'name_en',c.name_en,'name_my',c.name_my,'is_active',c.is_active) end) order by l.created_at desc),'[]'::jsonb) from public.listings l join public.profiles p on p.id=l.owner_id left join public.stores s on s.id=l.store_id join public.listing_videos v on v.listing_id=l.id join public.media_assets vm on vm.id=v.video_media_id join public.media_assets tm on tm.id=v.thumbnail_media_id left join public.cities c on c.id=l.city_id where public.is_listing_public(l.id); $$;
create or replace function public.get_public_stores() returns jsonb language sql stable security definer set search_path='' as $$
 select coalesce(jsonb_agg(jsonb_build_object('id',s.id,'owner_id',s.owner_id,'name',s.name,'description',s.description,'category_id',s.category_id,'phone',s.phone,'viber_phone',s.viber_phone,'email',s.email,'city',s.city,'city_id',s.city_id,'location',s.location,'latitude',s.latitude,'longitude',s.longitude,'opening_time',s.opening_time,'closing_time',s.closing_time,'status',s.status,'is_promoted',s.is_promoted,'promotion_start_at',s.promotion_start_at,'promotion_end_at',s.promotion_end_at,'created_at',s.created_at) order by s.created_at desc),'[]'::jsonb) from public.stores s where s.status='approved' and not s.is_hidden and s.deleted_at is null; $$;
create or replace function public.owner_delete_unapproved_store(p_store_id uuid) returns void language plpgsql security definer set search_path='' as $$ begin delete from public.stores where id=p_store_id and owner_id=auth.uid() and status in ('pending','rejected'); if not found then raise exception 'store_not_deletable'; end if; end; $$;
create or replace function public.owner_resubmit_rejected_store(p_store_id uuid) returns void language plpgsql security definer set search_path='' as $$ begin update public.stores set status='pending',rejection_reason=null where id=p_store_id and owner_id=auth.uid() and status='rejected'; if not found then raise exception 'store_not_resubmittable'; end if; end; $$;
create or replace function public.admin_set_profile_status(p_user_id uuid,p_status text) returns void language plpgsql security definer set search_path='' as $$ begin if not public.is_active_admin() then raise exception 'admin_required'; end if; update public.profiles set status=p_status::public.profile_status where id=p_user_id; end; $$;
create or replace function public.admin_moderate_listing(p_listing_id uuid,p_status text) returns void language plpgsql security definer set search_path='' as $$ begin if not public.is_active_admin() then raise exception 'admin_required'; end if; if p_status='deleted' then update public.listings set is_hidden=true,deleted_at=now() where id=p_listing_id; else update public.listings set status=p_status::public.listing_status where id=p_listing_id; end if; end; $$;
create or replace function public.admin_set_store_status(p_store_id uuid,p_status text) returns void language plpgsql security definer set search_path='' as $$ begin if not public.is_active_admin() then raise exception 'admin_required'; end if; update public.stores set status=p_status::public.store_status,approved_by=case when p_status='approved' then auth.uid() else approved_by end,approved_at=case when p_status='approved' then now() else approved_at end where id=p_store_id; end; $$;
create or replace function public.admin_set_store_promoted(p_store_id uuid,p_promoted boolean) returns void language plpgsql security definer set search_path='' as $$ begin if not public.is_active_admin() then raise exception 'admin_required'; end if; update public.stores set is_promoted=p_promoted where id=p_store_id; end; $$;
create or replace function public.review_report(p_report_id uuid,p_status text) returns void language plpgsql security definer set search_path='' as $$ begin if not public.is_active_admin() then raise exception 'admin_required'; end if; update public.reports set status=p_status::public.report_status,reviewed_by=auth.uid(),reviewed_at=now() where id=p_report_id; end; $$;
create or replace function public.review_store_edit_request(p_request_id uuid,p_approved boolean) returns void language plpgsql security definer set search_path='' as $$ declare r public.store_edit_requests; begin if not public.is_active_admin() then raise exception 'admin_required'; end if; select * into r from public.store_edit_requests where id=p_request_id and status='pending' for update; if not found then raise exception 'request_not_pending'; end if; if p_approved then update public.stores set name=coalesce(r.proposed_changes->>'name',name),description=coalesce(r.proposed_changes->>'description',description),category_id=coalesce((r.proposed_changes->>'category_id')::uuid,category_id),phone=coalesce(r.proposed_changes->>'phone',phone),viber_phone=coalesce(r.proposed_changes->>'viber_phone',viber_phone),email=coalesce(r.proposed_changes->>'email',email),city=coalesce(r.proposed_changes->>'city',city),location=coalesce(r.proposed_changes->>'location',location) where id=r.store_id; end if; update public.store_edit_requests set status=case when p_approved then 'approved' else 'rejected' end,reviewed_by=auth.uid(),reviewed_at=now() where id=p_request_id; end; $$;
create or replace function public.review_promotion_request(p_request_id uuid,p_approved boolean) returns void language plpgsql security definer set search_path='' as $$ declare r public.promotion_requests; begin if not public.is_active_admin() then raise exception 'admin_required'; end if; select * into r from public.promotion_requests where id=p_request_id and status='pending' for update; if not found then raise exception 'request_not_pending'; end if; update public.promotion_requests set status=case when p_approved then 'approved' else 'rejected' end,reviewed_by=auth.uid(),reviewed_at=now() where id=p_request_id; if p_approved then update public.stores set is_promoted=true,promotion_start_at=r.requested_start_at,promotion_end_at=r.requested_end_at where id=r.store_id; end if; end; $$;
create or replace function public.can_read_listing_video_object(p_bucket text,p_object_path text) returns boolean language sql stable security definer set search_path='' as $$ select public.is_active_admin() or exists(select 1 from public.listing_videos v join public.listings l on l.id=v.listing_id join public.media_assets m on m.id in(v.video_media_id,v.thumbnail_media_id) where m.bucket=p_bucket and m.object_path=p_object_path and (l.owner_id=auth.uid() or public.is_listing_public(l.id))); $$;

create trigger auth_user_profile after insert on auth.users for each row execute function public.handle_new_auth_user_profile();
create trigger profiles_updated before update on public.profiles for each row execute function public.set_updated_at(); create trigger admin_roles_updated before update on public.admin_roles for each row execute function public.set_updated_at(); create trigger categories_updated before update on public.categories for each row execute function public.set_updated_at(); create trigger cities_updated before update on public.cities for each row execute function public.set_updated_at(); create trigger media_updated before update on public.media_assets for each row execute function public.set_updated_at(); create trigger stores_updated before update on public.stores for each row execute function public.set_updated_at(); create trigger listings_updated before update on public.listings for each row execute function public.set_updated_at(); create trigger reports_updated before update on public.reports for each row execute function public.set_updated_at(); create trigger store_requests_updated before update on public.store_edit_requests for each row execute function public.set_updated_at(); create trigger promotion_requests_updated before update on public.promotion_requests for each row execute function public.set_updated_at(); create trigger tiktok_updated before update on public.tiktok_videos for each row execute function public.set_updated_at(); create trigger banners_updated before update on public.banners for each row execute function public.set_updated_at();
create trigger listings_store_owner before insert or update on public.listings for each row execute function public.enforce_store_listing_owner(); create trigger listing_video_ready after insert on public.listing_videos for each row execute function public.mark_listing_video_ready(); create trigger listing_video_not_ready after delete on public.listing_videos for each row execute function public.clear_listing_video_ready(); create trigger likes_notify after insert on public.listing_likes for each row execute function public.notify_listing_owner_on_like(); create trigger stores_notify after insert on public.stores for each row when(new.status='pending') execute function public.notify_admin_on_store(); create trigger listings_notify after insert on public.listings for each row execute function public.notify_admin_on_listing();

alter table public.profiles enable row level security; alter table public.admin_roles enable row level security; alter table public.categories enable row level security; alter table public.cities enable row level security; alter table public.media_assets enable row level security; alter table public.stores enable row level security; alter table public.listings enable row level security; alter table public.listing_videos enable row level security; alter table public.listing_likes enable row level security; alter table public.listing_views enable row level security; alter table public.reports enable row level security; alter table public.notifications enable row level security; alter table public.admin_notifications enable row level security; alter table public.store_edit_requests enable row level security; alter table public.promotion_requests enable row level security; alter table public.tiktok_videos enable row level security; alter table public.banners enable row level security;
create policy profiles_select on public.profiles for select to authenticated using(id=auth.uid() or public.is_active_admin()); create policy profiles_update on public.profiles for update to authenticated using(id=auth.uid() and public.is_active_user()) with check(id=auth.uid() and public.is_active_user()); create policy roles_select on public.admin_roles for select to authenticated using(public.is_active_admin());
create policy categories_select on public.categories for select using(is_active or public.is_active_admin()); create policy categories_admin on public.categories for all to authenticated using(public.is_active_admin()) with check(public.is_active_admin()); create policy cities_select on public.cities for select using(is_active or public.is_active_admin()); create policy cities_admin on public.cities for all to authenticated using(public.is_active_admin()) with check(public.is_active_admin());
create policy media_select on public.media_assets for select to authenticated using(owner_id=auth.uid() or public.is_active_admin()); create policy media_insert on public.media_assets for insert to authenticated with check(owner_id=auth.uid() and public.is_active_user()); create policy media_delete on public.media_assets for delete to authenticated using(owner_id=auth.uid() or public.is_active_admin());
create policy stores_select on public.stores for select using((status='approved' and not is_hidden and deleted_at is null) or owner_id=auth.uid() or public.is_active_admin()); create policy stores_insert on public.stores for insert to authenticated with check(owner_id=auth.uid() and status='pending' and public.is_active_user()); create policy stores_update on public.stores for update to authenticated using(owner_id=auth.uid() or public.is_active_admin()) with check(owner_id=auth.uid() or public.is_active_admin()); create policy stores_delete on public.stores for delete to authenticated using((owner_id=auth.uid() and status in ('pending','rejected')) or public.is_active_admin());
create policy listings_select on public.listings for select using(public.is_listing_public(id) or owner_id=auth.uid() or public.is_active_admin()); create policy listings_insert on public.listings for insert to authenticated with check(owner_id=auth.uid() and public.is_active_user()); create policy listings_update on public.listings for update to authenticated using(owner_id=auth.uid() or public.is_active_admin()) with check(owner_id=auth.uid() or public.is_active_admin()); create policy listing_videos_select on public.listing_videos for select using(public.is_listing_public(listing_id) or exists(select 1 from public.listings where id=listing_id and owner_id=auth.uid()) or public.is_active_admin()); create policy listing_videos_write on public.listing_videos for all to authenticated using(public.is_active_admin() or exists(select 1 from public.listings where id=listing_id and owner_id=auth.uid())) with check(public.is_active_admin() or exists(select 1 from public.listings where id=listing_id and owner_id=auth.uid()));
create policy reports_insert on public.reports for insert with check(true); create policy reports_admin on public.reports for select to authenticated using(public.is_active_admin()); create policy notifications_owner on public.notifications for select to authenticated using(recipient_id=auth.uid()); create policy notifications_read on public.notifications for update to authenticated using(recipient_id=auth.uid()) with check(recipient_id=auth.uid()); create policy admin_notifications_admin on public.admin_notifications for select to authenticated using(public.is_active_admin()); create policy admin_notifications_read on public.admin_notifications for update to authenticated using(public.is_active_admin()) with check(public.is_active_admin());
create policy edit_requests_owner on public.store_edit_requests for all to authenticated using(owner_id=auth.uid() or public.is_active_admin()) with check(owner_id=auth.uid() or public.is_active_admin()); create policy promotion_requests_owner on public.promotion_requests for all to authenticated using(owner_id=auth.uid() or public.is_active_admin()) with check(owner_id=auth.uid() or public.is_active_admin()); create policy tiktok_select on public.tiktok_videos for select using(is_active or public.is_active_admin()); create policy tiktok_admin on public.tiktok_videos for all to authenticated using(public.is_active_admin()) with check(public.is_active_admin()); create policy banners_select on public.banners for select using(public.is_active_admin() or (is_active and (start_at is null or start_at<=now()) and (end_at is null or end_at>=now()))); create policy banners_admin on public.banners for all to authenticated using(public.is_active_admin()) with check(public.is_active_admin());

insert into storage.buckets(id,name,public) values ('profile-images','profile-images',true),('store-images','store-images',true),('banner-images','banner-images',true),('listing-videos','listing-videos',false),('listing-thumbnails','listing-thumbnails',false);
create policy profile_storage_read on storage.objects for select using(bucket_id='profile-images'); create policy profile_storage_write on storage.objects for all to authenticated using(bucket_id='profile-images' and (storage.foldername(name))[1]=auth.uid()::text) with check(bucket_id='profile-images' and (storage.foldername(name))[1]=auth.uid()::text);
create policy store_storage_read on storage.objects for select using(bucket_id='store-images'); create policy store_storage_write on storage.objects for all to authenticated using(bucket_id='store-images' and public.is_active_user()) with check(bucket_id='store-images' and public.is_active_user());
create policy banner_storage_read on storage.objects for select using(bucket_id='banner-images'); create policy banner_storage_admin on storage.objects for all to authenticated using(bucket_id='banner-images' and public.is_active_admin()) with check(bucket_id='banner-images' and public.is_active_admin());
create policy listing_video_storage_read on storage.objects for select using(bucket_id in ('listing-videos','listing-thumbnails') and public.can_read_listing_video_object(bucket_id,name)); create policy listing_video_storage_insert on storage.objects for insert to authenticated with check(bucket_id in ('listing-videos','listing-thumbnails') and (storage.foldername(name))[1]='listings' and (storage.foldername(name))[2]='drafts' and (storage.foldername(name))[3]=auth.uid()::text and public.is_active_user()); create policy listing_video_storage_delete on storage.objects for delete to authenticated using(bucket_id in ('listing-videos','listing-thumbnails') and (public.is_active_admin() or (storage.foldername(name))[3]=auth.uid()::text));

revoke all on all tables in schema public from anon, authenticated; grant select on public.categories,public.cities,public.tiktok_videos,public.banners to anon,authenticated; grant insert on public.reports to anon; grant select,insert,update,delete on public.profiles,public.stores,public.listings,public.listing_videos,public.media_assets,public.reports,public.notifications,public.store_edit_requests,public.promotion_requests,public.admin_notifications to authenticated;
revoke all on all functions in schema public from public; grant execute on function public.is_active_admin(),public.is_active_user(),public.is_listing_public(uuid),public.sync_current_profile_from_auth(),public.get_public_listings(),public.get_public_stores(),public.get_listing_like_count(uuid),public.get_listing_view_count(uuid),public.toggle_listing_like(uuid,text),public.record_listing_view(uuid,text),public.resolve_city_for_coordinates(double precision,double precision),public.can_read_listing_video_object(text,text) to anon,authenticated; grant execute on function public.owner_delete_unapproved_store(uuid),public.owner_resubmit_rejected_store(uuid),public.admin_set_profile_status(uuid,text),public.admin_moderate_listing(uuid,text),public.admin_set_store_status(uuid,text),public.admin_set_store_promoted(uuid,boolean),public.review_report(uuid,text),public.review_store_edit_request(uuid,boolean),public.review_promotion_request(uuid,boolean) to authenticated;
commit;
