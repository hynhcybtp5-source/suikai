begin;

-- Canonical helpers use the new active admin role. The legacy helper remains
-- as a compatibility wrapper because migrations 0002 and 0005 reference it.
create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select public.is_active_admin();
$$;

revoke all on function public.is_admin() from public;
grant execute on function public.is_admin() to anon, authenticated, service_role;

create or replace function public.is_active_user()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.profiles p
    where p.id = (select auth.uid())
      and p.status = 'active'
  );
$$;

revoke all on function public.is_active_user() from public;
grant execute on function public.is_active_user()
to authenticated, service_role;

create or replace function public.is_listing_public(p_listing_id uuid)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.listings l
    left join public.stores s on s.id = l.store_id
    where l.id = p_listing_id
      and l.is_published = true
      and l.is_hidden = false
      and l.deleted_at is null
      and (
        (
          l.listing_type = 'general'
          and l.status in ('available', 'reserved')
        )
        or
        (
          l.listing_type = 'store'
          and l.status = 'available'
          and s.lifecycle_status = 'active'
          and s.is_hidden = false
          and s.deleted_at is null
        )
      )
  );
$$;

revoke all on function public.is_listing_public(uuid) from public;
grant execute on function public.is_listing_public(uuid)
to anon, authenticated, service_role;

-- Keep both legacy and canonical store statuses consistent. Owners submit
-- requests; only an active admin may change approval-controlled fields.
create or replace function public.guard_store_admin_fields()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_active_admin() then
    new.status := old.status;
    new.lifecycle_status := old.lifecycle_status;
    new.approved_by := old.approved_by;
    new.approved_at := old.approved_at;
    new.rejection_reason := old.rejection_reason;
    new.is_promoted := old.is_promoted;
    new.promotion_start_at := old.promotion_start_at;
    new.promotion_end_at := old.promotion_end_at;
  end if;
  return new;
end;
$$;

revoke all on function public.guard_store_admin_fields() from public;

create or replace function public.enforce_store_listing_publish()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  current_store_status public.store_status;
  current_store_owner uuid;
  current_store_hidden boolean;
  current_store_deleted_at timestamptz;
begin
  if new.listing_type = 'store' then
    select s.status, s.owner_id, s.is_hidden, s.deleted_at
    into current_store_status, current_store_owner,
         current_store_hidden, current_store_deleted_at
    from public.stores s
    where s.id = new.store_id;

    if current_store_owner is null or current_store_owner <> new.owner_id then
      raise exception 'Store listing owner must own the store';
    end if;

    if current_store_status is distinct from 'approved'
       or current_store_hidden = true
       or current_store_deleted_at is not null then
      new.is_published := false;
      new.published_at := null;
    end if;
  elsif tg_op = 'INSERT' then
    new.is_published := true;
    new.published_at := coalesce(new.published_at, now());
  end if;

  if new.is_hidden or new.deleted_at is not null then
    new.is_published := false;
  end if;

  if new.listing_type = 'store' and new.status = 'deleted' then
    new.deleted_at := coalesce(new.deleted_at, now());
    new.is_published := false;
  end if;

  return new;
end;
$$;

create or replace function public.publish_store_listings_after_approval()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if new.status = 'approved' and old.status is distinct from 'approved' then
    update public.listings
    set
      is_published = true,
      published_at = coalesce(published_at, now())
    where store_id = new.id
      and is_hidden = false
      and deleted_at is null
      and status <> 'deleted';
  elsif new.status is distinct from 'approved' then
    update public.listings
    set is_published = false
    where store_id = new.id;
  end if;
  return new;
end;
$$;

-- Harden existing policies. ALTER POLICY avoids dropping schema objects.
alter policy "public read approved stores"
on public.stores
using (
  (
    lifecycle_status = 'active'
    and is_hidden = false
    and deleted_at is null
  )
  or owner_id = (select auth.uid())
  or public.is_active_admin()
);

alter policy "authenticated create own store"
on public.stores
with check (
  owner_id = (select auth.uid())
  and public.is_active_user()
  and status = 'pending'
  and lifecycle_status = 'pending'
  and approved_by is null
  and approved_at is null
  and category_id is not null
  and is_promoted = false
);

alter policy "owner update own store"
on public.stores
using (public.is_active_admin())
with check (public.is_active_admin());

alter policy "admin delete stores"
on public.stores
using (false);

alter policy "public read published listings"
on public.listings
using (
  public.is_listing_public(id)
  or owner_id = (select auth.uid())
  or public.is_active_admin()
);

alter policy "authenticated create own listings"
on public.listings
with check (
  owner_id = (select auth.uid())
  and public.is_active_user()
  and category_id is not null
  and (
    (listing_type = 'general' and store_id is null)
    or
    (
      listing_type = 'store'
      and exists (
        select 1
        from public.stores s
        where s.id = store_id
          and s.owner_id = (select auth.uid())
          and s.lifecycle_status = 'active'
          and s.is_hidden = false
          and s.deleted_at is null
      )
    )
  )
);

alter policy "owner update own listings"
on public.listings
using (
  (
    owner_id = (select auth.uid())
    and public.is_active_user()
  )
  or public.is_active_admin()
)
with check (
  public.is_active_admin()
  or
  (
    owner_id = (select auth.uid())
    and public.is_active_user()
    and (
      (listing_type = 'general' and store_id is null)
      or
      (
        listing_type = 'store'
        and exists (
          select 1
          from public.stores s
          where s.id = store_id
            and s.owner_id = (select auth.uid())
            and s.lifecycle_status = 'active'
        )
      )
    )
  )
);

alter policy "owner delete own listings"
on public.listings
using (false);

alter policy "public read listing images"
on public.listing_images
using (
  public.is_listing_public(listing_id)
  or exists (
    select 1
    from public.listings l
    where l.id = listing_id
      and (
        l.owner_id = (select auth.uid())
        or public.is_active_admin()
      )
  )
);

alter policy "owner manage listing images"
on public.listing_images
using (
  exists (
    select 1
    from public.listings l
    where l.id = listing_id
      and (
        (
          l.owner_id = (select auth.uid())
          and public.is_active_user()
        )
        or public.is_active_admin()
      )
  )
)
with check (
  exists (
    select 1
    from public.listings l
    where l.id = listing_id
      and (
        (
          l.owner_id = (select auth.uid())
          and public.is_active_user()
        )
        or public.is_active_admin()
      )
  )
);

alter policy "public read likes"
on public.listing_likes
using (false);

alter policy "public create like"
on public.listing_likes
with check (false);

alter policy "public read views"
on public.listing_views
using (false);

alter policy "public create views"
on public.listing_views
with check (false);

alter policy "public create reports"
on public.reports
with check (
  workflow_status = 'pending'
  and status = 'open'
  and reviewed_by is null
  and reviewed_at is null
  and (reporter_id is null or reporter_id = (select auth.uid()))
  and ((listing_id is not null) <> (store_id is not null))
);

alter policy "admin read reports"
on public.reports
using (public.is_active_admin());

alter policy "admin update reports"
on public.reports
using (public.is_active_admin())
with check (public.is_active_admin());

alter policy "admin delete reports"
on public.reports
using (false);

alter policy "public read active categories"
on public.categories
using (true);

alter policy "admin manage categories"
on public.categories
using (public.is_active_admin())
with check (public.is_active_admin());

-- New marketplace tables.
alter table public.media_assets enable row level security;
alter table public.store_edit_requests enable row level security;
alter table public.promotion_requests enable row level security;
alter table public.notifications enable row level security;
alter table public.admin_audit_logs enable row level security;

create policy "owners read media metadata"
on public.media_assets
for select to authenticated
using (owner_id = (select auth.uid()) or public.is_active_admin());

create policy "active users create media metadata"
on public.media_assets
for insert to authenticated
with check (
  owner_id = (select auth.uid())
  and public.is_active_user()
);

create policy "owners manage media metadata"
on public.media_assets
for update to authenticated
using (
  (
    owner_id = (select auth.uid())
    and public.is_active_user()
  )
  or public.is_active_admin()
)
with check (
  (
    owner_id = (select auth.uid())
    and public.is_active_user()
  )
  or public.is_active_admin()
);

create policy "owners delete media metadata"
on public.media_assets
for delete to authenticated
using (
  (
    owner_id = (select auth.uid())
    and public.is_active_user()
  )
  or public.is_active_admin()
);

create or replace function public.prepare_store_edit_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  current_store public.stores%rowtype;
begin
  if not public.is_active_user() then
    raise exception 'Active user required';
  end if;

  select * into current_store
  from public.stores s
  where s.id = new.store_id
  for update;

  if current_store.id is null
     or current_store.owner_id <> (select auth.uid()) then
    raise exception 'Store owner required';
  end if;

  new.owner_id := (select auth.uid());
  new.before_snapshot := to_jsonb(current_store);
  new.status := 'pending';
  new.reviewed_by := null;
  new.reviewed_at := null;
  new.review_note := null;
  return new;
end;
$$;

revoke all on function public.prepare_store_edit_request() from public;

create trigger store_edit_requests_prepare
before insert on public.store_edit_requests
for each row execute function public.prepare_store_edit_request();

create policy "owners read store edit requests"
on public.store_edit_requests
for select to authenticated
using (owner_id = (select auth.uid()) or public.is_active_admin());

create policy "owners create store edit requests"
on public.store_edit_requests
for insert to authenticated
with check (
  owner_id = (select auth.uid())
  and public.is_active_user()
  and status = 'pending'
);

create or replace function public.prepare_promotion_request()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_active_user()
     or not exists (
       select 1
       from public.stores s
       where s.id = new.store_id
         and s.owner_id = (select auth.uid())
         and s.lifecycle_status = 'active'
     ) then
    raise exception 'Active store owner required';
  end if;

  new.owner_id := (select auth.uid());
  new.status := 'pending';
  new.reviewed_by := null;
  new.reviewed_at := null;
  new.review_note := null;
  return new;
end;
$$;

revoke all on function public.prepare_promotion_request() from public;

create trigger promotion_requests_prepare
before insert on public.promotion_requests
for each row execute function public.prepare_promotion_request();

create policy "owners read promotion requests"
on public.promotion_requests
for select to authenticated
using (owner_id = (select auth.uid()) or public.is_active_admin());

create policy "owners create promotion requests"
on public.promotion_requests
for insert to authenticated
with check (
  owner_id = (select auth.uid())
  and public.is_active_user()
  and status = 'pending'
);

create policy "users read own notifications"
on public.notifications
for select to authenticated
using (recipient_id = (select auth.uid()) or public.is_active_admin());

create policy "users mark own notifications read"
on public.notifications
for update to authenticated
using (recipient_id = (select auth.uid()))
with check (recipient_id = (select auth.uid()));

create policy "active admins read audit logs"
on public.admin_audit_logs
for select to authenticated
using (public.is_active_admin());

-- Audit all admin mutations on marketplace moderation tables.
create or replace function public.audit_admin_mutation()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  old_data jsonb;
  new_data jsonb;
  record_id text;
begin
  if not public.is_active_admin() then
    if tg_op = 'DELETE' then
      return old;
    end if;
    return new;
  end if;

  old_data := case when tg_op = 'INSERT' then null else to_jsonb(old) end;
  new_data := case when tg_op = 'DELETE' then null else to_jsonb(new) end;
  record_id := coalesce(new_data ->> 'id', old_data ->> 'id');

  insert into public.admin_audit_logs (
    actor_id,
    action,
    target_type,
    target_id,
    before_data,
    after_data
  ) values (
    (select auth.uid()),
    tg_op,
    tg_table_name,
    record_id,
    old_data,
    new_data
  );

  if tg_op = 'DELETE' then
    return old;
  end if;
  return new;
end;
$$;

revoke all on function public.audit_admin_mutation() from public;

create trigger stores_admin_audit
after insert or update or delete on public.stores
for each row execute function public.audit_admin_mutation();
create trigger listings_admin_audit
after insert or update or delete on public.listings
for each row execute function public.audit_admin_mutation();
create trigger categories_admin_audit
after insert or update or delete on public.categories
for each row execute function public.audit_admin_mutation();
create trigger reports_admin_audit
after insert or update or delete on public.reports
for each row execute function public.audit_admin_mutation();
create trigger store_edit_requests_admin_audit
after update on public.store_edit_requests
for each row execute function public.audit_admin_mutation();
create trigger promotion_requests_admin_audit
after update on public.promotion_requests
for each row execute function public.audit_admin_mutation();

-- Admin workflows are RPC-only and verify the caller on the server.
create or replace function public.review_store_application(
  p_store_id uuid,
  p_approved boolean,
  p_review_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  store_owner uuid;
begin
  if not public.is_active_admin() then
    raise exception 'Active admin required';
  end if;

  select s.owner_id into store_owner
  from public.stores s
  where s.id = p_store_id
  for update;

  if store_owner is null then
    raise exception 'Store not found';
  end if;

  update public.stores
  set
    status = case when p_approved then 'approved' else 'rejected' end,
    lifecycle_status = case
      when p_approved then 'active'::public.canonical_store_status
      else 'rejected'::public.canonical_store_status
    end,
    approved_by = case when p_approved then (select auth.uid()) else null end,
    approved_at = case when p_approved then now() else null end,
    rejection_reason = case when p_approved then null else p_review_note end
  where id = p_store_id;

  insert into public.notifications (recipient_id, event_type, payload)
  values (
    store_owner,
    case
      when p_approved then 'store_application_approved'
      else 'store_application_rejected'
    end,
    jsonb_build_object('store_id', p_store_id, 'review_note', p_review_note)
  );
end;
$$;

create or replace function public.review_store_edit_request(
  p_request_id uuid,
  p_approved boolean,
  p_review_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  request_row public.store_edit_requests%rowtype;
begin
  if not public.is_active_admin() then
    raise exception 'Active admin required';
  end if;

  select * into request_row
  from public.store_edit_requests r
  where r.id = p_request_id
  for update;

  if request_row.id is null or request_row.status <> 'pending' then
    raise exception 'Pending request not found';
  end if;

  if p_approved then
    update public.stores
    set
      name = coalesce(nullif(btrim(request_row.proposed_changes ->> 'name'), ''), name),
      description = case
        when request_row.proposed_changes ? 'description'
          then request_row.proposed_changes ->> 'description'
        else description
      end,
      category_id = case
        when request_row.proposed_changes ? 'category_id'
          then nullif(request_row.proposed_changes ->> 'category_id', '')::uuid
        else category_id
      end,
      category = case
        when request_row.proposed_changes ? 'category'
          then request_row.proposed_changes ->> 'category'
        else category
      end,
      phone = case when request_row.proposed_changes ? 'phone'
        then request_row.proposed_changes ->> 'phone' else phone end,
      viber_phone = case when request_row.proposed_changes ? 'viber_phone'
        then request_row.proposed_changes ->> 'viber_phone' else viber_phone end,
      email = case when request_row.proposed_changes ? 'email'
        then request_row.proposed_changes ->> 'email' else email end,
      city = case when request_row.proposed_changes ? 'city'
        then request_row.proposed_changes ->> 'city' else city end,
      location = case when request_row.proposed_changes ? 'location'
        then request_row.proposed_changes ->> 'location' else location end,
      latitude = case when request_row.proposed_changes ? 'latitude'
        then nullif(request_row.proposed_changes ->> 'latitude', '')::double precision
        else latitude end,
      longitude = case when request_row.proposed_changes ? 'longitude'
        then nullif(request_row.proposed_changes ->> 'longitude', '')::double precision
        else longitude end,
      opening_time = case when request_row.proposed_changes ? 'opening_time'
        then nullif(request_row.proposed_changes ->> 'opening_time', '')::time
        else opening_time end,
      closing_time = case when request_row.proposed_changes ? 'closing_time'
        then nullif(request_row.proposed_changes ->> 'closing_time', '')::time
        else closing_time end,
      logo_url = case when request_row.proposed_changes ? 'logo_url'
        then request_row.proposed_changes ->> 'logo_url' else logo_url end,
      cover_url = case when request_row.proposed_changes ? 'cover_url'
        then request_row.proposed_changes ->> 'cover_url' else cover_url end,
      logo_media_id = case when request_row.proposed_changes ? 'logo_media_id'
        then nullif(request_row.proposed_changes ->> 'logo_media_id', '')::uuid
        else logo_media_id end,
      cover_media_id = case when request_row.proposed_changes ? 'cover_media_id'
        then nullif(request_row.proposed_changes ->> 'cover_media_id', '')::uuid
        else cover_media_id end
    where id = request_row.store_id;
  end if;

  update public.store_edit_requests
  set
    status = case when p_approved then 'approved' else 'rejected' end,
    reviewed_by = (select auth.uid()),
    reviewed_at = now(),
    review_note = p_review_note
  where id = p_request_id;

  insert into public.notifications (recipient_id, event_type, payload)
  values (
    request_row.owner_id,
    case when p_approved then 'store_edit_approved' else 'store_edit_rejected' end,
    jsonb_build_object(
      'request_id', p_request_id,
      'store_id', request_row.store_id,
      'review_note', p_review_note
    )
  );
end;
$$;

create or replace function public.review_promotion_request(
  p_request_id uuid,
  p_approved boolean,
  p_review_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  request_row public.promotion_requests%rowtype;
begin
  if not public.is_active_admin() then
    raise exception 'Active admin required';
  end if;

  select * into request_row
  from public.promotion_requests r
  where r.id = p_request_id
  for update;

  if request_row.id is null or request_row.status <> 'pending' then
    raise exception 'Pending request not found';
  end if;

  if p_approved then
    update public.stores
    set
      is_promoted = true,
      promotion_start_at = request_row.requested_start_at,
      promotion_end_at = request_row.requested_end_at
    where id = request_row.store_id;
  end if;

  update public.promotion_requests
  set
    status = case when p_approved then 'approved' else 'rejected' end,
    reviewed_by = (select auth.uid()),
    reviewed_at = now(),
    review_note = p_review_note
  where id = p_request_id;

  insert into public.notifications (recipient_id, event_type, payload)
  values (
    request_row.owner_id,
    case when p_approved then 'promotion_approved' else 'promotion_rejected' end,
    jsonb_build_object(
      'request_id', p_request_id,
      'store_id', request_row.store_id,
      'review_note', p_review_note
    )
  );
end;
$$;

create or replace function public.review_report(
  p_report_id uuid,
  p_status public.canonical_report_status,
  p_resolution_note text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if not public.is_active_admin() then
    raise exception 'Active admin required';
  end if;

  if p_status = 'pending' then
    raise exception 'Review status must not be pending';
  end if;

  update public.reports
  set
    workflow_status = p_status,
    status = case p_status
      when 'reviewed' then 'reviewing'::public.report_status
      when 'resolved' then 'resolved'::public.report_status
      else 'dismissed'::public.report_status
    end,
    reviewed_by = (select auth.uid()),
    reviewed_at = now(),
    resolution_note = p_resolution_note
  where id = p_report_id;

  if not found then
    raise exception 'Report not found';
  end if;
end;
$$;

revoke all on function public.review_store_application(uuid, boolean, text) from public;
revoke all on function public.review_store_edit_request(uuid, boolean, text) from public;
revoke all on function public.review_promotion_request(uuid, boolean, text) from public;
revoke all on function public.review_report(uuid, public.canonical_report_status, text) from public;

grant execute on function public.review_store_application(uuid, boolean, text)
to authenticated, service_role;
grant execute on function public.review_store_edit_request(uuid, boolean, text)
to authenticated, service_role;
grant execute on function public.review_promotion_request(uuid, boolean, text)
to authenticated, service_role;
grant execute on function public.review_report(uuid, public.canonical_report_status, text)
to authenticated, service_role;

-- Device identifiers are hashed server-side. Direct table writes are blocked.
create or replace function public.toggle_listing_like(
  p_listing_id uuid,
  p_device_id text
)
returns boolean
language plpgsql
security definer
set search_path = ''
as $$
declare
  device_hash text;
  existing_like uuid;
begin
  if p_device_id is null or length(btrim(p_device_id)) < 8 then
    raise exception 'Invalid device id';
  end if;

  if not public.is_listing_public(p_listing_id) then
    raise exception 'Listing not available';
  end if;

  device_hash := encode(digest(btrim(p_device_id), 'sha256'), 'hex');

  select id into existing_like
  from public.listing_likes
  where listing_id = p_listing_id and device_id = device_hash
  limit 1;

  if existing_like is not null then
    delete from public.listing_likes where id = existing_like;
    return false;
  end if;

  insert into public.listing_likes (listing_id, device_id, user_id)
  values (p_listing_id, device_hash, (select auth.uid()))
  on conflict (listing_id, device_id) do nothing;
  return true;
end;
$$;

create or replace function public.record_listing_view(
  p_listing_id uuid,
  p_device_id text default null
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  device_hash text;
begin
  if p_device_id is null or length(btrim(p_device_id)) < 8 then
    return;
  end if;

  if not public.is_listing_public(p_listing_id) then
    return;
  end if;

  device_hash := encode(digest(btrim(p_device_id), 'sha256'), 'hex');

  insert into public.listing_views (listing_id, device_id, view_key)
  values (p_listing_id, device_hash, device_hash)
  on conflict (listing_id, view_key) where view_key is not null do nothing;
end;
$$;

revoke all on function public.toggle_listing_like(uuid, text) from public;
revoke all on function public.record_listing_view(uuid, text) from public;
grant execute on function public.toggle_listing_like(uuid, text)
to anon, authenticated, service_role;
grant execute on function public.record_listing_view(uuid, text)
to anon, authenticated, service_role;

-- Explicit API privileges: public reads, owner writes, and RPC-only admin work.
revoke all on table public.stores from public, anon, authenticated;
grant select on table public.stores to anon, authenticated;
grant insert on table public.stores to authenticated;

revoke all on table public.listings from public, anon, authenticated;
grant select on table public.listings to anon, authenticated;
grant insert, update on table public.listings to authenticated;

revoke all on table public.listing_images from public, anon, authenticated;
grant select on table public.listing_images to anon, authenticated;
grant insert, update, delete on table public.listing_images to authenticated;

revoke all on table public.listing_likes from public, anon, authenticated;
revoke all on table public.listing_views from public, anon, authenticated;

revoke all on table public.reports from public, anon, authenticated;
grant insert on table public.reports to anon, authenticated;
grant select, update on table public.reports to authenticated;

revoke all on table public.categories from public, anon, authenticated;
grant select on table public.categories to anon, authenticated;
grant insert, update on table public.categories to authenticated;

revoke all on table public.media_assets from public, anon, authenticated;
grant select, insert, update, delete on table public.media_assets to authenticated;

revoke all on table public.store_edit_requests from public, anon, authenticated;
grant select, insert on table public.store_edit_requests to authenticated;

revoke all on table public.promotion_requests from public, anon, authenticated;
grant select, insert on table public.promotion_requests to authenticated;

revoke all on table public.notifications from public, anon, authenticated;
grant select on table public.notifications to authenticated;
grant update (is_read, read_at) on table public.notifications to authenticated;

revoke all on table public.admin_audit_logs from public, anon, authenticated;
grant select on table public.admin_audit_logs to authenticated;

grant all on table public.stores, public.listings, public.listing_images,
  public.listing_likes, public.listing_views, public.reports,
  public.categories, public.media_assets, public.store_edit_requests,
  public.promotion_requests, public.notifications, public.admin_audit_logs
to service_role;

-- Storage paths are listing/store/profile scoped. Existing public reads remain.
insert into storage.buckets (id, name, public)
values ('profile-images', 'profile-images', true)
on conflict (id) do nothing;

alter policy "owners upload listing media"
on storage.objects
with check (
  bucket_id = 'listing-images'
  and (storage.foldername(name))[1] = 'listings'
  and exists (
    select 1
    from public.listings l
    where l.id::text = (storage.foldername(name))[2]
      and l.owner_id = (select auth.uid())
      and public.is_active_user()
  )
);

alter policy "owners upload store media"
on storage.objects
with check (
  bucket_id = 'store-images'
  and (storage.foldername(name))[1] = 'stores'
  and exists (
    select 1
    from public.stores s
    where s.id::text = (storage.foldername(name))[2]
      and s.owner_id = (select auth.uid())
      and public.is_active_user()
  )
);

create policy "public read profile media"
on storage.objects for select
using (bucket_id = 'profile-images');

create policy "users upload own profile media"
on storage.objects for insert to authenticated
with check (
  bucket_id = 'profile-images'
  and (storage.foldername(name))[1] = 'profiles'
  and (storage.foldername(name))[2] = (select auth.uid())::text
  and public.is_active_user()
);

create policy "owners update listing media"
on storage.objects for update to authenticated
using (
  bucket_id = 'listing-images'
  and (storage.foldername(name))[1] = 'listings'
  and exists (
    select 1 from public.listings l
    where l.id::text = (storage.foldername(name))[2]
      and (l.owner_id = (select auth.uid()) or public.is_active_admin())
  )
)
with check (
  bucket_id = 'listing-images'
  and (storage.foldername(name))[1] = 'listings'
  and exists (
    select 1 from public.listings l
    where l.id::text = (storage.foldername(name))[2]
      and (l.owner_id = (select auth.uid()) or public.is_active_admin())
  )
);

create policy "owners delete listing media"
on storage.objects for delete to authenticated
using (
  bucket_id = 'listing-images'
  and (storage.foldername(name))[1] = 'listings'
  and exists (
    select 1 from public.listings l
    where l.id::text = (storage.foldername(name))[2]
      and (l.owner_id = (select auth.uid()) or public.is_active_admin())
  )
);

create policy "owners update store media"
on storage.objects for update to authenticated
using (
  bucket_id = 'store-images'
  and (storage.foldername(name))[1] = 'stores'
  and exists (
    select 1 from public.stores s
    where s.id::text = (storage.foldername(name))[2]
      and (s.owner_id = (select auth.uid()) or public.is_active_admin())
  )
)
with check (
  bucket_id = 'store-images'
  and (storage.foldername(name))[1] = 'stores'
  and exists (
    select 1 from public.stores s
    where s.id::text = (storage.foldername(name))[2]
      and (s.owner_id = (select auth.uid()) or public.is_active_admin())
  )
);

create policy "owners delete store media"
on storage.objects for delete to authenticated
using (
  bucket_id = 'store-images'
  and (storage.foldername(name))[1] = 'stores'
  and exists (
    select 1 from public.stores s
    where s.id::text = (storage.foldername(name))[2]
      and (s.owner_id = (select auth.uid()) or public.is_active_admin())
  )
);

create policy "users update own profile media"
on storage.objects for update to authenticated
using (
  bucket_id = 'profile-images'
  and (storage.foldername(name))[2] = (select auth.uid())::text
)
with check (
  bucket_id = 'profile-images'
  and (storage.foldername(name))[2] = (select auth.uid())::text
);

create policy "users delete own profile media"
on storage.objects for delete to authenticated
using (
  bucket_id = 'profile-images'
  and (
    (storage.foldername(name))[2] = (select auth.uid())::text
    or public.is_active_admin()
  )
);

commit;
