begin;

create or replace function public.require_listing_city_text()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.city := nullif(btrim(new.city), '');
  if new.city is null then
    raise exception using
      errcode = '23502',
      message = 'listing city is required';
  end if;
  return new;
end;
$$;

drop trigger if exists require_listing_city_text on public.listings;
create trigger require_listing_city_text
before insert or update of city on public.listings
for each row execute function public.require_listing_city_text();

commit;
