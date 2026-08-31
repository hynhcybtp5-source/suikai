begin;

-- Reuse the existing admin-only moderation RPC. This adds the inverse of its
-- existing `hidden` action without widening table privileges or RLS.
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
  elsif p_status = 'visible' then
    update public.listings
    set is_hidden = false,
        is_published = status in ('available', 'reserved') and deleted_at is null
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

revoke all on function public.admin_moderate_listing(uuid, text) from public;
grant execute on function public.admin_moderate_listing(uuid, text)
to authenticated, service_role;

commit;
