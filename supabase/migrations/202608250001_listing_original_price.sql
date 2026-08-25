-- `price` remains the sale price. `original_price` is shown only when it is
-- higher, making the discount explicit without changing existing listings.
alter table public.listings
  add column if not exists original_price numeric(18,2);

alter table public.listings
  drop constraint if exists listings_original_price_not_below_sale_price;

alter table public.listings
  add constraint listings_original_price_not_below_sale_price
  check (original_price is null or original_price >= price);

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
   'id',id,'owner_id',owner_id,'store_id',store_id,'listing_type',listing_type,'title',title,'description',description,'category_id',category_id,'price',price,'original_price',original_price,'currency',currency,'city',city,'city_id',city_id,'phone',phone,'viber_phone',viber_phone,'status',status,'latitude',case when is_location_visible then latitude else null end,'longitude',case when is_location_visible then longitude else null end,'is_location_visible',is_location_visible,'is_published',is_published,'is_hidden',false,'deleted_at',null,'created_at',created_at,'updated_at',updated_at,'seller_verified',seller_verified,'store_verified',store_verified,'sold_count',sold_count,'ranking_score',round(ranking_score::numeric,2),
   'listing_images',coalesce((select jsonb_agg(jsonb_build_object('id',li.id,'image_url',li.image_url,'media_id',li.media_id,'sort_order',li.sort_order) order by li.sort_order,li.created_at) from public.listing_images li where li.listing_id=scored.id),'[]'::jsonb)
 ) order by ranking_score desc, created_at desc), '[]'::jsonb) from (select * from scored order by ranking_score desc, created_at desc limit least(greatest(coalesce(p_limit,200),1),500)) scored;
$$;
