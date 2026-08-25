begin;
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
    status = case
      when p_approved then 'approved'::public.store_status
      else 'rejected'::public.store_status
    end,
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
      description = case when request_row.proposed_changes ? 'description'
        then request_row.proposed_changes ->> 'description' else description end,
      category_id = case when request_row.proposed_changes ? 'category_id'
        then nullif(request_row.proposed_changes ->> 'category_id', '')::uuid
        else category_id end,
      category = case when request_row.proposed_changes ? 'category'
        then request_row.proposed_changes ->> 'category' else category end,
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
    status = case
      when p_approved then 'approved'::public.request_status
      else 'rejected'::public.request_status
    end,
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
    status = case
      when p_approved then 'approved'::public.promotion_status
      else 'rejected'::public.promotion_status
    end,
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

  device_hash := encode(extensions.digest(btrim(p_device_id), 'sha256'), 'hex');

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

  device_hash := encode(extensions.digest(btrim(p_device_id), 'sha256'), 'hex');

  insert into public.listing_views (listing_id, device_id, view_key)
  values (p_listing_id, device_hash, device_hash)
  on conflict (listing_id, view_key) where view_key is not null do nothing;
end;
$$;
revoke all on function public.review_store_application(uuid, boolean, text) from public;
revoke all on function public.review_store_edit_request(uuid, boolean, text) from public;
revoke all on function public.review_promotion_request(uuid, boolean, text) from public;
revoke all on function public.toggle_listing_like(uuid, text) from public;
revoke all on function public.record_listing_view(uuid, text) from public;
grant execute on function public.review_store_application(uuid, boolean, text)
to authenticated, service_role;
grant execute on function public.review_store_edit_request(uuid, boolean, text)
to authenticated, service_role;
grant execute on function public.review_promotion_request(uuid, boolean, text)
to authenticated, service_role;
grant execute on function public.toggle_listing_like(uuid, text)
to anon, authenticated, service_role;
grant execute on function public.record_listing_view(uuid, text)
to anon, authenticated, service_role;
commit;
