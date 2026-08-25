begin;

-- Additive trust metadata.  These columns are deliberately admin-owned: no
-- client grant below permits changing them.
alter table public.profiles
  add column if not exists is_verified boolean not null default false,
  add column if not exists verified_at timestamptz,
  add column if not exists verified_by uuid references public.admin_roles(user_id) on delete set null,
  add column if not exists suspended_at timestamptz,
  add column if not exists suspended_by uuid references public.admin_roles(user_id) on delete set null,
  add column if not exists suspension_reason text;

alter table public.stores
  add column if not exists is_verified boolean not null default false,
  add column if not exists verified_at timestamptz,
  add column if not exists verified_by uuid references public.admin_roles(user_id) on delete set null,
  add column if not exists suspended_at timestamptz,
  add column if not exists suspended_by uuid references public.admin_roles(user_id) on delete set null,
  add column if not exists suspension_reason text;

create table if not exists public.user_blocks (
  blocker_id uuid not null references public.profiles(id) on delete cascade,
  blocked_user_id uuid not null references public.profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (blocker_id, blocked_user_id),
  check (blocker_id <> blocked_user_id)
);
create index if not exists user_blocks_blocked_idx on public.user_blocks (blocked_user_id);
alter table public.user_blocks enable row level security;
create policy "users manage own blocks" on public.user_blocks for all to authenticated
  using (blocker_id = (select auth.uid())) with check (blocker_id = (select auth.uid()));
revoke all on public.user_blocks from public, anon, authenticated;
grant select, insert, delete on public.user_blocks to authenticated;

-- Reports can now target a seller as well as an existing listing/store.
alter table public.reports add column if not exists reported_user_id uuid references public.profiles(id) on delete cascade;
alter table public.reports drop constraint if exists report_target;
alter table public.reports drop constraint if exists reports_exactly_one_target;
alter table public.reports add constraint reports_one_target check (
  ((listing_id is not null)::int + (store_id is not null)::int + (reported_user_id is not null)::int) = 1
) not valid;
create index if not exists reports_pending_created_idx
  on public.reports (workflow_status, created_at desc) where workflow_status = 'pending';

-- A tiny server-side throttle state; action keys are either the signed-in user
-- or a hash of the existing device identifier, never raw client identifiers.
create table if not exists public.action_rate_limits (
  action text not null,
  actor_key text not null,
  last_action_at timestamptz not null default now(),
  primary key (action, actor_key)
);
revoke all on public.action_rate_limits from public, anon, authenticated;

create or replace function public.enforce_action_rate_limit(p_action text, p_actor_key text, p_window interval)
returns void language plpgsql security definer set search_path = '' as $$
declare v_last timestamptz;
begin
  select last_action_at into v_last from public.action_rate_limits
  where action = p_action and actor_key = p_actor_key for update;
  if v_last is not null and v_last > now() - p_window then
    raise exception 'rate_limited' using errcode = 'P0001';
  end if;
  insert into public.action_rate_limits(action, actor_key, last_action_at)
  values (p_action, p_actor_key, now())
  on conflict (action, actor_key) do update set last_action_at = excluded.last_action_at;
end;
$$;

create or replace function public.create_report(
  p_reason text, p_listing_id uuid default null, p_store_id uuid default null, p_user_id uuid default null, p_device_id text default null
) returns uuid language plpgsql security definer set search_path = '' as $$
declare v_id uuid := gen_random_uuid(); v_actor text;
begin
  if nullif(btrim(p_reason), '') is null then raise exception 'Report reason required'; end if;
  if ((p_listing_id is not null)::int + (p_store_id is not null)::int + (p_user_id is not null)::int) <> 1 then
    raise exception 'Exactly one report target is required';
  end if;
  v_actor := coalesce((select auth.uid())::text, encode(digest(coalesce(nullif(btrim(p_device_id), ''), 'anonymous'), 'sha256'), 'hex'));
  perform public.enforce_action_rate_limit('report', v_actor, interval '60 seconds');
  insert into public.reports(id, listing_id, store_id, reported_user_id, reporter_id, reporter_device_hash, reason, status, workflow_status)
  values (v_id, p_listing_id, p_store_id, p_user_id, (select auth.uid()),
    case when p_device_id is null then null else encode(digest(btrim(p_device_id), 'sha256'), 'hex') end,
    left(btrim(p_reason), 2000), 'open', 'pending');
  insert into public.admin_notifications(type, title, message)
  values ('new_report', 'มีรายงานใหม่', left(btrim(p_reason), 180));
  return v_id;
end;
$$;

-- Preserve the established toggle semantics while throttling repeated taps and
-- blocking interactions with sellers the current user chose to hide.
create or replace function public.toggle_listing_like(p_listing_id uuid, p_device_id text)
returns boolean language plpgsql security definer set search_path = '' as $$
declare v_device text; v_existing uuid; v_owner uuid; v_actor text;
begin
  if p_device_id is null or length(btrim(p_device_id)) < 8 then raise exception 'Invalid device id'; end if;
  if not public.is_listing_public(p_listing_id) then raise exception 'Listing not available'; end if;
  select owner_id into v_owner from public.listings where id = p_listing_id;
  if (select auth.uid()) is not null and exists (select 1 from public.user_blocks b where b.blocker_id = (select auth.uid()) and b.blocked_user_id = v_owner) then
    raise exception 'seller_blocked';
  end if;
  v_device := encode(digest(btrim(p_device_id), 'sha256'), 'hex');
  select id into v_existing from public.listing_likes where listing_id = p_listing_id and device_id = v_device limit 1;
  v_actor := coalesce((select auth.uid())::text, v_device);
  perform public.enforce_action_rate_limit('like', v_actor || ':' || p_listing_id::text, interval '2 seconds');
  if v_existing is not null then delete from public.listing_likes where id = v_existing; return false; end if;
  insert into public.listing_likes(listing_id, device_id, user_id) values (p_listing_id, v_device, (select auth.uid())) on conflict (listing_id, device_id) do nothing;
  return true;
end;
$$;

-- Suspension is recorded with an actor, time and reason and cannot be forged
-- by an app client.  Existing audit triggers continue to retain old data.
drop function if exists public.admin_set_profile_status(uuid, public.profile_status);
create or replace function public.admin_set_profile_status(p_user_id uuid, p_status public.profile_status, p_reason text default null)
returns void language plpgsql security definer set search_path = '' as $$
begin
  if not public.is_active_admin() then raise exception 'Active admin required'; end if;
  if p_user_id = (select auth.uid()) and p_status = 'suspended' then raise exception 'Admin cannot suspend own account'; end if;
  update public.profiles set status = p_status,
    suspended_at = case when p_status = 'suspended' then now() else null end,
    suspended_by = case when p_status = 'suspended' then (select auth.uid()) else null end,
    suspension_reason = case when p_status = 'suspended' then nullif(btrim(p_reason), '') else null end
  where id = p_user_id;
  if not found then raise exception 'Profile not found'; end if;
  if p_status = 'suspended' then insert into public.notifications(recipient_id,event_type,payload)
    values (p_user_id,'account_suspended',jsonb_build_object('reason',p_reason)); end if;
end;
$$;

drop function if exists public.admin_set_store_status(uuid, text);
create or replace function public.admin_set_store_status(p_store_id uuid, p_status text, p_reason text default null)
returns void language plpgsql security definer set search_path = '' as $$
declare v_owner uuid;
begin
  if not public.is_active_admin() then raise exception 'Active admin required'; end if;
  select owner_id into v_owner from public.stores where id = p_store_id for update;
  if v_owner is null then raise exception 'Store not found'; end if;
  update public.stores set status = case p_status when 'active' then 'approved'::public.store_status when 'approved' then 'approved'::public.store_status when 'pending' then 'pending'::public.store_status when 'suspended' then 'suspended'::public.store_status when 'rejected' then 'rejected'::public.store_status else status end,
    lifecycle_status = case p_status when 'active' then 'active'::public.canonical_store_status when 'approved' then 'active'::public.canonical_store_status when 'pending' then 'pending'::public.canonical_store_status when 'suspended' then 'suspended'::public.canonical_store_status when 'rejected' then 'rejected'::public.canonical_store_status else lifecycle_status end,
    suspended_at = case when p_status = 'suspended' then now() else null end,
    suspended_by = case when p_status = 'suspended' then (select auth.uid()) else null end,
    suspension_reason = case when p_status = 'suspended' then nullif(btrim(p_reason), '') else null end
  where id = p_store_id;
  if p_status = 'suspended' then
    update public.listings set is_published = false where store_id = p_store_id;
    insert into public.notifications(recipient_id,event_type,payload) values (v_owner,'store_suspended',jsonb_build_object('store_id',p_store_id,'reason',p_reason));
  end if;
end;
$$;

-- Public, privacy-safe feed projection with logarithmic engagement and a
-- 14-day half-life.  Coordinates are optional; when supplied, nearby products
-- receive up to 12 points but distant/unknown products still rank normally.
create or replace function public.get_ranked_public_listings(p_latitude double precision default null, p_longitude double precision default null, p_limit integer default 200)
returns jsonb language sql stable security definer set search_path = '' as $$
 with visible as (
   select l.*, s.is_verified as store_verified, p.is_verified as seller_verified,
     coalesce((select count(*) from public.listing_likes lk where lk.listing_id=l.id),0)::int likes,
     coalesce((select count(*) from public.listing_views vw where vw.listing_id=l.id),0)::int views,
     coalesce((select count(*) from public.listings sold where sold.owner_id=l.owner_id and sold.status='sold'),0)::int sold_count
   from public.listings l left join public.stores s on s.id=l.store_id join public.profiles p on p.id=l.owner_id
   where l.is_published and not l.is_hidden and l.deleted_at is null and l.status in ('available','reserved') and p.status='active'
     and (l.store_id is null or (s.status='approved' and s.lifecycle_status='active' and not s.is_hidden and s.deleted_at is null))
     and not exists (select 1 from public.user_blocks b where b.blocker_id=(select auth.uid()) and b.blocked_user_id=l.owner_id)
 ), scored as (
   select visible.*, greatest(0, 42 * exp(-ln(2) * extract(epoch from (now()-created_at))/1209600)) +
     least(18, 5*ln(1+likes)) + least(14, 2.5*ln(1+views)) + least(10, 2*ln(1+sold_count)) +
     case when p_latitude is not null and p_longitude is not null and latitude is not null and longitude is not null then greatest(0, 12 - 0.08 * (6371 * acos(least(1, greatest(-1, cos(radians(p_latitude))*cos(radians(latitude))*cos(radians(longitude)-radians(p_longitude))+sin(radians(p_latitude))*sin(radians(latitude))))))) else 0 end as ranking_score
   from visible
 )
 select coalesce(jsonb_agg(jsonb_build_object(
   'id',id,'owner_id',owner_id,'store_id',store_id,'listing_type',listing_type,'title',title,'description',description,'category_id',category_id,'price',price,'currency',currency,'city',city,'city_id',city_id,'phone',phone,'viber_phone',viber_phone,'status',status,'latitude',case when is_location_visible then latitude else null end,'longitude',case when is_location_visible then longitude else null end,'is_location_visible',is_location_visible,'is_published',is_published,'is_hidden',false,'deleted_at',null,'created_at',created_at,'updated_at',updated_at,'seller_verified',seller_verified,'store_verified',store_verified,'sold_count',sold_count,'ranking_score',round(ranking_score::numeric,2),
   'listing_images',coalesce((select jsonb_agg(jsonb_build_object('id',li.id,'image_url',li.image_url,'media_id',li.media_id,'sort_order',li.sort_order) order by li.sort_order,li.created_at) from public.listing_images li where li.listing_id=scored.id),'[]'::jsonb)
 ) order by ranking_score desc, created_at desc), '[]'::jsonb) from (select * from scored order by ranking_score desc, created_at desc limit least(greatest(coalesce(p_limit,200),1),500)) scored;
$$;

create or replace function public.get_public_listings()
returns jsonb language sql stable security definer set search_path = '' as $$ select public.get_ranked_public_listings(null, null, 200); $$;

-- One aggregate RPC prevents the admin dashboard from doing unbounded client
-- counts.  Breakdown arrays are intentionally capped for a predictable payload.
create or replace function public.admin_analytics(p_period text default '30d')
returns jsonb language plpgsql stable security definer set search_path = '' as $$
declare v_since timestamptz := case p_period when 'today' then date_trunc('day',now()) when '7d' then now()-interval '7 days' when '30d' then now()-interval '30 days' else '-infinity'::timestamptz end;
begin
 if not public.is_active_admin() then raise exception 'Active admin required'; end if;
 return jsonb_build_object(
  'period',p_period,'users_total',(select count(*) from public.profiles),'users_new',(select count(*) from public.profiles where created_at>=v_since),
  'stores_total',(select count(*) from public.stores),'stores_new',(select count(*) from public.stores where created_at>=v_since),'stores_pending',(select count(*) from public.stores where status='pending' and lifecycle_status='pending'),
  'listings_total',(select count(*) from public.listings where deleted_at is null),'listings_new',(select count(*) from public.listings where created_at>=v_since),'sold_total',(select count(*) from public.listings where status='sold'),
  'views_total',(select count(*) from public.listing_views),'likes_total',(select count(*) from public.listing_likes),
  'categories',(select coalesce(jsonb_agg(x),'[]'::jsonb) from (select jsonb_build_object('name',coalesce(c.name_th,l.category,''),'count',count(*)) x from public.listings l left join public.categories c on c.id=l.category_id where l.deleted_at is null group by coalesce(c.name_th,l.category,'') order by count(*) desc limit 8) q),
  'cities',(select coalesce(jsonb_agg(x),'[]'::jsonb) from (select jsonb_build_object('name',coalesce(city,''),'count',count(*)) x from public.listings where deleted_at is null group by coalesce(city,'') order by count(*) desc limit 8) q),
  'stores_top',(select coalesce(jsonb_agg(x),'[]'::jsonb) from (select jsonb_build_object('id',s.id,'name',s.name,'count',count(l.id)) x from public.stores s left join public.listings l on l.store_id=s.id and l.deleted_at is null group by s.id,s.name order by count(l.id) desc,s.created_at desc limit 8) q),
  'listings_top',(select coalesce(jsonb_agg(x),'[]'::jsonb) from (select jsonb_build_object('id',l.id,'title',l.title,'likes',count(distinct lk.id),'views',count(distinct vw.id)) x from public.listings l left join public.listing_likes lk on lk.listing_id=l.id left join public.listing_views vw on vw.listing_id=l.id where l.deleted_at is null group by l.id,l.title order by (count(distinct lk.id)+count(distinct vw.id)) desc,l.created_at desc limit 8) q)
 );
end; $$;

create index if not exists listings_ranking_feed_idx on public.listings (created_at desc) where is_published and not is_hidden and deleted_at is null;
create index if not exists listings_sold_owner_idx on public.listings (owner_id) where status = 'sold';
create index if not exists listing_likes_listing_created_idx on public.listing_likes (listing_id, created_at desc);
create index if not exists listing_views_listing_created_idx on public.listing_views (listing_id, created_at desc);

-- Database guard is intentionally separate from RLS so a future policy change
-- cannot accidentally allow content to be created for a suspended store.
create or replace function public.guard_trusted_content_creation()
returns trigger language plpgsql security definer set search_path = '' as $$
declare v_profile_status public.profile_status; v_store_status public.store_status;
begin
  select status into v_profile_status from public.profiles where id = new.owner_id;
  if v_profile_status is distinct from 'active' then raise exception 'account_suspended'; end if;
  if new.store_id is not null then
    select status into v_store_status from public.stores where id = new.store_id;
    if v_store_status = 'suspended' then raise exception 'store_suspended'; end if;
  end if;
  return new;
end; $$;
drop trigger if exists listings_guard_trusted_content_creation on public.listings;
create trigger listings_guard_trusted_content_creation before insert on public.listings
for each row execute function public.guard_trusted_content_creation();
revoke all on function public.guard_trusted_content_creation() from public;

revoke all on function public.enforce_action_rate_limit(text,text,interval) from public;
revoke all on function public.create_report(text,uuid,uuid,uuid,text) from public;
revoke all on function public.get_ranked_public_listings(double precision,double precision,integer) from public;
revoke all on function public.admin_analytics(text) from public;
revoke insert on public.reports from anon, authenticated;
grant execute on function public.create_report(text,uuid,uuid,uuid,text), public.get_ranked_public_listings(double precision,double precision,integer) to anon, authenticated, service_role;
grant execute on function public.admin_analytics(text), public.admin_set_profile_status(uuid,public.profile_status,text), public.admin_set_store_status(uuid,text,text) to authenticated, service_role;

commit;
