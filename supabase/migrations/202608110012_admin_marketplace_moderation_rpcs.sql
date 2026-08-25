begin;
create or replace function public.admin_set_profile_status(
  p_user_id uuid,
  p_status public.profile_status
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  before_row jsonb;
begin
  if not public.is_active_admin() then
    raise exception 'Active admin required';
  end if;
  if p_user_id = (select auth.uid()) and p_status = 'suspended' then
    raise exception 'Admin cannot suspend own account';
  end if;

  select to_jsonb(p) into before_row from public.profiles p where p.id = p_user_id;
  update public.profiles set status = p_status where id = p_user_id;
  if not found then raise exception 'Profile not found'; end if;

  insert into public.admin_audit_logs (
    actor_id, action, target_type, target_id, before_data, after_data
  ) values (
    (select auth.uid()), 'set_status', 'profile', p_user_id::text,
    before_row, (select to_jsonb(p) from public.profiles p where p.id = p_user_id)
  );
end;
$$;
create or replace function public.admin_moderate_listing(
  p_listing_id uuid,
  p_status text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  listing_kind public.listing_type;
begin
  if not public.is_active_admin() then
    raise exception 'Active admin required';
  end if;

  select l.listing_type into listing_kind
  from public.listings l where l.id = p_listing_id for update;
  if listing_kind is null then raise exception 'Listing not found'; end if;

  if p_status = 'hidden' then
    update public.listings set is_hidden = true, is_published = false
    where id = p_listing_id;
  elsif p_status = 'deleted' then
    if listing_kind = 'store' then
      update public.listings
      set status = 'deleted', deleted_at = coalesce(deleted_at, now()),
          is_hidden = true, is_published = false
      where id = p_listing_id;
    else
      update public.listings
      set deleted_at = coalesce(deleted_at, now()), is_hidden = true,
          is_published = false
      where id = p_listing_id;
    end if;
  elsif listing_kind = 'general' and p_status in ('available','reserved','sold') then
    update public.listings
    set status = p_status::public.listing_status,
        is_published = p_status <> 'sold'
    where id = p_listing_id;
  elsif listing_kind = 'store' and p_status in ('available','out_of_stock') then
    update public.listings
    set status = p_status::public.listing_status,
        is_published = p_status = 'available'
    where id = p_listing_id;
  else
    raise exception 'Invalid status for listing type';
  end if;
end;
$$;
create or replace function public.admin_set_store_status(
  p_store_id uuid,
  p_status text
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

  update public.stores
  set
    status = case p_status
      when 'active' then 'approved'::public.store_status
      when 'approved' then 'approved'::public.store_status
      when 'pending' then 'pending'::public.store_status
      when 'suspended' then 'suspended'::public.store_status
      when 'rejected' then 'rejected'::public.store_status
      else status
    end,
    lifecycle_status = case p_status
      when 'active' then 'active'::public.canonical_store_status
      when 'approved' then 'active'::public.canonical_store_status
      when 'pending' then 'pending'::public.canonical_store_status
      when 'suspended' then 'suspended'::public.canonical_store_status
      when 'rejected' then 'rejected'::public.canonical_store_status
      else lifecycle_status
    end,
    approved_by = case when p_status in ('active','approved')
      then (select auth.uid()) else approved_by end,
    approved_at = case when p_status in ('active','approved')
      then coalesce(approved_at, now()) else approved_at end
  where id = p_store_id
    and p_status in ('active','approved','pending','suspended','rejected');

  if not found then raise exception 'Store not found or invalid status'; end if;
end;
$$;
create or replace function public.admin_set_store_promoted(
  p_store_id uuid,
  p_promoted boolean
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

  update public.stores
  set is_promoted = p_promoted,
      promotion_start_at = case when p_promoted
        then coalesce(promotion_start_at, now()) else null end,
      promotion_end_at = case when p_promoted then promotion_end_at else null end
  where id = p_store_id and lifecycle_status = 'active';
  if not found then raise exception 'Active store not found'; end if;
end;
$$;
revoke execute on function public.admin_set_profile_status(
  uuid, public.profile_status
) from public, anon;
revoke execute on function public.admin_moderate_listing(uuid, text)
from public, anon;
revoke execute on function public.admin_set_store_status(uuid, text)
from public, anon;
revoke execute on function public.admin_set_store_promoted(uuid, boolean)
from public, anon;
grant execute on function public.admin_set_profile_status(
  uuid, public.profile_status
) to authenticated, service_role;
grant execute on function public.admin_moderate_listing(uuid, text)
to authenticated, service_role;
grant execute on function public.admin_set_store_status(uuid, text)
to authenticated, service_role;
grant execute on function public.admin_set_store_promoted(uuid, boolean)
to authenticated, service_role;
commit;
