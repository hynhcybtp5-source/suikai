begin;

alter table public.stores add column if not exists cover_url text;
alter table public.stores add column if not exists email text;

alter type public.listing_status add value if not exists 'deleted';

commit;
begin;

alter table public.listings
  add constraint listings_supported_currency
  check (currency in ('MMK', 'THB', 'USD', 'CNY')) not valid;

alter table public.listings validate constraint listings_supported_currency;

create or replace function public.publish_store_listings_after_approval()
returns trigger language plpgsql as $$
begin
  if new.status = 'approved' and old.status is distinct from 'approved' then
    update public.listings
      set is_published = true, published_at = coalesce(published_at, now())
      where store_id = new.id and status not in ('sold', 'deleted');
  elsif new.status is distinct from 'approved' then
    update public.listings set is_published = false
      where store_id = new.id;
  end if;
  return new;
end;
$$;

create trigger stores_publish_listings_after_approval
after update of status on public.stores
for each row execute function public.publish_store_listings_after_approval();

insert into storage.buckets (id, name, public)
values ('listing-images', 'listing-images', true), ('store-images', 'store-images', true)
on conflict (id) do update set public = excluded.public;

create policy "public read listing media" on storage.objects for select
using (bucket_id = 'listing-images');
create policy "owners upload listing media" on storage.objects for insert to authenticated
with check (bucket_id = 'listing-images' and (storage.foldername(name))[1] = 'listings');

create policy "public read store media" on storage.objects for select
using (bucket_id = 'store-images');
create policy "owners upload store media" on storage.objects for insert to authenticated
with check (bucket_id = 'store-images' and (storage.foldername(name))[1] = 'stores');

commit;
