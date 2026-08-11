begin;

-- =========================================================
-- 1. ปิดการ DELETE Like โดยตรง
--    การยกเลิก Like จะทำผ่าน RPC เท่านั้น
-- =========================================================

drop policy if exists "public remove own device like"
on public.listing_likes;


-- =========================================================
-- 2. RPC: Toggle Like
--    device เดียวกดสินค้าเดียวได้เพียง 1 Like
-- =========================================================

create or replace function public.toggle_listing_like(
  p_listing_id uuid,
  p_device_id text
)
returns boolean
language plpgsql
security definer
set search_path = public
as $$
declare
  existing_like uuid;
begin

  if p_device_id is null
     or length(trim(p_device_id)) < 8 then
    raise exception 'Invalid device id';
  end if;

  if not exists (
    select 1
    from public.listings
    where id = p_listing_id
      and is_published = true
      and status <> 'sold'
  ) then
    raise exception 'Listing not available';
  end if;

  select id
  into existing_like
  from public.listing_likes
  where listing_id = p_listing_id
    and device_id = p_device_id
  limit 1;

  if existing_like is not null then

    delete from public.listing_likes
    where id = existing_like;

    return false;

  else

    insert into public.listing_likes (
      listing_id,
      device_id
    )
    values (
      p_listing_id,
      p_device_id
    )
    on conflict (listing_id, device_id)
    do nothing;

    return true;

  end if;

end;
$$;


-- =========================================================
-- 3. RPC: นับ Like
-- =========================================================

create or replace function public.get_listing_like_count(
  p_listing_id uuid
)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select count(*)
  from public.listing_likes
  where listing_id = p_listing_id;
$$;


-- =========================================================
-- 4. RPC: บันทึก View
-- =========================================================

create or replace function public.record_listing_view(
  p_listing_id uuid,
  p_device_id text default null
)
returns void
language plpgsql
security definer
set search_path = public
as $$
begin

  if not exists (
    select 1
    from public.listings
    where id = p_listing_id
      and is_published = true
      and status <> 'sold'
  ) then
    return;
  end if;

  insert into public.listing_views (
    listing_id,
    device_id
  )
  values (
    p_listing_id,
    nullif(trim(p_device_id), '')
  );

end;
$$;


-- =========================================================
-- 5. RPC: จำนวน View
-- =========================================================

create or replace function public.get_listing_view_count(
  p_listing_id uuid
)
returns bigint
language sql
stable
security definer
set search_path = public
as $$
  select count(*)
  from public.listing_views
  where listing_id = p_listing_id;
$$;


-- =========================================================
-- 6. ปรับ View สถิติให้ใช้ RLS ของผู้เรียก
-- =========================================================

drop view if exists public.listing_stats;

create view public.listing_stats
with (security_invoker = true)
as
select
  l.id as listing_id,

  (
    select count(*)
    from public.listing_likes lk
    where lk.listing_id = l.id
  ) as like_count,

  (
    select count(*)
    from public.listing_views vw
    where vw.listing_id = l.id
  ) as view_count

from public.listings l;


-- =========================================================
-- 7. สิทธิ์ RPC
-- =========================================================

revoke all
on function public.toggle_listing_like(uuid, text)
from public;

revoke all
on function public.record_listing_view(uuid, text)
from public;

revoke all
on function public.get_listing_like_count(uuid)
from public;

revoke all
on function public.get_listing_view_count(uuid)
from public;


grant execute
on function public.toggle_listing_like(uuid, text)
to anon, authenticated;

grant execute
on function public.record_listing_view(uuid, text)
to anon, authenticated;

grant execute
on function public.get_listing_like_count(uuid)
to anon, authenticated;

grant execute
on function public.get_listing_view_count(uuid)
to anon, authenticated;

commit;
