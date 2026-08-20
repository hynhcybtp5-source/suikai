begin;

-- Keep profiles private while allowing visitors to view the public identity
-- of a seller who has at least one public listing.
create or replace function public.get_public_seller_profile(p_owner_id uuid)
returns jsonb
language sql
stable
security definer
set search_path = ''
as $$
  select jsonb_build_object(
    'id', p.id,
    'name', coalesce(p.name, ''),
    'city', coalesce(p.city, ''),
    'city_id', p.city_id,
    'created_at', p.created_at,
    'avatar_bucket', m.bucket,
    'avatar_path', m.object_path
  )
  from public.profiles p
  left join public.media_assets m on m.id = p.avatar_media_id
  where p.id = p_owner_id
    and exists (
      select 1
      from public.listings l
      left join public.stores s on s.id = l.store_id
      where l.owner_id = p.id
        and l.is_published = true
        and l.is_hidden = false
        and l.deleted_at is null
        and l.status in ('available', 'reserved')
        and (
          l.store_id is null
          or (
            s.status = 'approved'
            and s.lifecycle_status = 'active'
            and s.is_hidden = false
            and s.deleted_at is null
          )
        )
    );
$$;

revoke all on function public.get_public_seller_profile(uuid) from public;
grant execute on function public.get_public_seller_profile(uuid)
to anon, authenticated, service_role;

commit;
