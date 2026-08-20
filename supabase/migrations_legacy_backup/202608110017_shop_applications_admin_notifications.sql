begin;

-- Store rows with status=pending are the canonical shop applications.
-- This table is deliberately separate from user notifications so no client
-- can choose an admin recipient or manufacture a privileged alert.
create table public.admin_notifications (
  id uuid primary key default gen_random_uuid(),
  type text not null check (length(btrim(type)) > 0),
  shop_id uuid references public.stores(id) on delete cascade,
  title text not null check (length(btrim(title)) > 0),
  message text,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index admin_notifications_unread_idx
on public.admin_notifications (is_read, created_at desc);

create index admin_notifications_shop_idx
on public.admin_notifications (shop_id, created_at desc);

create unique index admin_notifications_shop_application_unique
on public.admin_notifications (shop_id, type)
where type = 'shop_application' and shop_id is not null;

alter table public.admin_notifications enable row level security;

create policy "active admins read admin notifications"
on public.admin_notifications
for select to authenticated
using (public.is_active_admin());

create policy "active admins mark admin notifications read"
on public.admin_notifications
for update to authenticated
using (public.is_active_admin())
with check (public.is_active_admin());

revoke all on table public.admin_notifications
from public, anon, authenticated;
grant select on table public.admin_notifications to authenticated;
grant update (is_read) on table public.admin_notifications to authenticated;
grant all on table public.admin_notifications to service_role;

create or replace function public.notify_admin_on_shop_application()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if new.status = 'pending' then
    insert into public.admin_notifications (
      type, shop_id, title, message
    ) values (
      'shop_application',
      new.id,
      'คำขอเปิดร้านใหม่',
      'ร้าน ' || new.name || ' ส่งคำขอเปิดร้าน'
    )
    on conflict do nothing;
  end if;
  return new;
end;
$$;

revoke execute on function public.notify_admin_on_shop_application()
from public, anon, authenticated;

create trigger stores_notify_admin_on_application
after insert on public.stores
for each row
when (new.status = 'pending')
execute function public.notify_admin_on_shop_application();

-- Preserve visibility for owners/admins while requiring both legacy and
-- canonical approval fields for public reads.
alter policy "public read approved stores"
on public.stores
using (
  (
    status = 'approved'
    and lifecycle_status = 'active'
    and is_hidden = false
    and deleted_at is null
  )
  or owner_id = (select auth.uid())
  or public.is_active_admin()
);

-- Existing real pending applications should not be invisible to the badge.
insert into public.admin_notifications (type, shop_id, title, message, created_at)
select
  'shop_application',
  s.id,
  'คำขอเปิดร้านใหม่',
  'ร้าน ' || s.name || ' ส่งคำขอเปิดร้าน',
  s.created_at
from public.stores s
where s.status = 'pending'
on conflict do nothing;

commit;
