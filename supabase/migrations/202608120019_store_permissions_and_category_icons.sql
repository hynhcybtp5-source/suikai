begin;

-- Existing category schema has no icon field. Keep one stable identifier that
-- both Admin and mobile/web clients can render without storing Flutter codes.
alter table public.categories
  add column if not exists icon_key text not null default 'category';

create or replace function public.owner_delete_unapproved_store(p_store_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  delete from public.stores
  where id = p_store_id
    and owner_id = (select auth.uid())
    and status in ('pending', 'rejected');
  if not found then
    raise exception 'Only the owner may delete a pending or rejected store';
  end if;
end;
$$;

revoke all on function public.owner_delete_unapproved_store(uuid) from public;
grant execute on function public.owner_delete_unapproved_store(uuid)
to authenticated, service_role;

create or replace function public.owner_resubmit_rejected_store(p_store_id uuid)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  update public.stores
  set status = 'pending', lifecycle_status = 'pending', rejection_reason = null
  where id = p_store_id
    and owner_id = (select auth.uid())
    and status = 'rejected';
  if not found then
    raise exception 'Only the owner may resubmit a rejected store';
  end if;
end;
$$;

revoke all on function public.owner_resubmit_rejected_store(uuid) from public;
grant execute on function public.owner_resubmit_rejected_store(uuid)
to authenticated, service_role;

-- Enforce approved-store permission in Postgres as well as Flutter UI/repository.
create or replace function public.enforce_store_listing_publish()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  current_store_status public.store_status;
  current_store_lifecycle public.canonical_store_status;
  current_store_owner uuid;
  current_store_hidden boolean;
  current_store_deleted_at timestamptz;
begin
  if new.listing_type = 'store' then
    select s.status, s.lifecycle_status, s.owner_id, s.is_hidden, s.deleted_at
      into current_store_status, current_store_lifecycle, current_store_owner,
           current_store_hidden, current_store_deleted_at
    from public.stores s where s.id = new.store_id;

    if current_store_owner is null or current_store_owner <> new.owner_id then
      raise exception 'Store listing owner must own the store';
    end if;
    if current_store_status is distinct from 'approved'
       or current_store_lifecycle is distinct from 'active'
       or current_store_hidden = true
       or current_store_deleted_at is not null then
      raise exception 'Store must be approved and active to manage products';
    end if;
  elsif tg_op = 'INSERT' then
    new.is_published := true;
    new.published_at := coalesce(new.published_at, now());
  end if;

  if new.is_hidden or new.deleted_at is not null then
    new.is_published := false;
  end if;
  if new.listing_type = 'store' and new.status = 'deleted' then
    new.deleted_at := coalesce(new.deleted_at, now());
    new.is_published := false;
  end if;
  return new;
end;
$$;

commit;
