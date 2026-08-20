begin;

-- Reuse admin_notifications and extend it for both listing kinds.
alter table public.admin_notifications
add column listing_id uuid references public.listings(id) on delete cascade;

create index admin_notifications_listing_idx
on public.admin_notifications (listing_id, created_at desc);

create unique index admin_notifications_new_listing_unique
on public.admin_notifications (listing_id, type)
where listing_id is not null
  and type in ('general_listing', 'store_product');

create or replace function public.notify_admin_on_new_listing()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.admin_notifications (
    type, listing_id, title, message, created_at
  ) values (
    case when new.listing_type = 'store'
      then 'store_product' else 'general_listing' end,
    new.id,
    case when new.listing_type = 'store'
      then 'สินค้าใหม่ในร้าน' else 'ประกาศใหม่' end,
    new.title,
    new.created_at
  ) on conflict do nothing;
  return new;
end;
$$;

revoke execute on function public.notify_admin_on_new_listing()
from public, anon, authenticated;

create trigger listings_notify_admin_on_insert
after insert on public.listings
for each row execute function public.notify_admin_on_new_listing();

create or replace function public.mark_shop_application_reviewed()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if old.status = 'pending' and new.status in ('approved', 'rejected') then
    update public.admin_notifications
    set is_read = true
    where type = 'shop_application' and shop_id = new.id;
  end if;
  return new;
end;
$$;

revoke execute on function public.mark_shop_application_reviewed()
from public, anon, authenticated;

create trigger stores_mark_application_reviewed
after update of status on public.stores
for each row execute function public.mark_shop_application_reviewed();

insert into public.admin_notifications (
  type, listing_id, title, message, created_at, is_read
)
select
  case when l.listing_type = 'store'
    then 'store_product' else 'general_listing' end,
  l.id,
  case when l.listing_type = 'store'
    then 'สินค้าใหม่ในร้าน' else 'ประกาศใหม่' end,
  l.title,
  l.created_at,
  true
from public.listings l
on conflict do nothing;

commit;
