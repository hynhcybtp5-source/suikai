begin;
alter policy "owners delete listing media"
on storage.objects
using (
  bucket_id = 'listing-images'
  and (storage.foldername(name))[1] = 'listings'
  and (
    public.is_active_admin()
    or (
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
alter policy "owners delete store media"
on storage.objects
using (
  bucket_id = 'store-images'
  and (storage.foldername(name))[1] = 'stores'
  and (
    public.is_active_admin()
    or (
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
commit;
