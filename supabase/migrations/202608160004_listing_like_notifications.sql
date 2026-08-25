begin;
create or replace function public.notify_listing_owner_on_like()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  listing_owner uuid;
  listing_title text;
begin
  select l.owner_id, l.title
  into listing_owner, listing_title
  from public.listings l
  where l.id = new.listing_id;

  if listing_owner is null or listing_owner = new.user_id then
    return new;
  end if;

  insert into public.notifications (recipient_id, event_type, payload)
  values (
    listing_owner,
    'listing_liked',
    jsonb_build_object(
      'listing_id', new.listing_id,
      'listing_title', listing_title
    )
  );
  return new;
end;
$$;
drop trigger if exists listing_likes_notify_owner on public.listing_likes;
create trigger listing_likes_notify_owner
after insert on public.listing_likes
for each row execute function public.notify_listing_owner_on_like();
revoke all on function public.notify_listing_owner_on_like() from public;
grant execute on function public.notify_listing_owner_on_like() to service_role;
commit;
