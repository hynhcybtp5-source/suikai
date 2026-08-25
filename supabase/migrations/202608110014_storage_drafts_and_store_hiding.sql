begin;
alter policy "owners upload listing media"
on storage.objects
with check (
  bucket_id = 'listing-images'
  and (storage.foldername(name))[1] = 'listings'
  and (
    (
      (storage.foldername(name))[2] = 'drafts'
      and (storage.foldername(name))[3] = (select auth.uid())::text
      and public.is_active_user()
    )
    or exists (
      select 1 from public.listings l
      where l.id::text = (storage.foldername(name))[2]
        and l.owner_id = (select auth.uid())
        and public.is_active_user()
    )
  )
);
alter policy "owners upload store media"
on storage.objects
with check (
  bucket_id = 'store-images'
  and (storage.foldername(name))[1] = 'stores'
  and (
    (
      (storage.foldername(name))[2] = 'drafts'
      and (storage.foldername(name))[3] = (select auth.uid())::text
      and public.is_active_user()
    )
    or exists (
      select 1 from public.stores s
      where s.id::text = (storage.foldername(name))[2]
        and s.owner_id = (select auth.uid())
        and public.is_active_user()
    )
  )
);
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

  if p_status = 'hidden' then
    update public.stores set is_hidden = true where id = p_store_id;
  else
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
      is_hidden = false,
      approved_by = case when p_status in ('active','approved')
        then (select auth.uid()) else approved_by end,
      approved_at = case when p_status in ('active','approved')
        then coalesce(approved_at, now()) else approved_at end
    where id = p_store_id
      and p_status in ('active','approved','pending','suspended','rejected');
  end if;

  if not found then raise exception 'Store not found or invalid status'; end if;
end;
$$;
revoke execute on function public.admin_set_store_status(uuid, text)
from public, anon;
grant execute on function public.admin_set_store_status(uuid, text)
to authenticated, service_role;
commit;
