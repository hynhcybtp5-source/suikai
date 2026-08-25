begin;
-- The legacy schema already owns store_status, listing_status, and
-- report_status. Keep it untouched and introduce explicit canonical types.
create type public.profile_status as enum ('active', 'suspended');
create type public.canonical_store_status as enum (
  'pending',
  'active',
  'suspended',
  'rejected'
);
create type public.canonical_listing_status as enum (
  'available',
  'reserved',
  'sold'
);
create type public.request_status as enum (
  'pending',
  'approved',
  'rejected'
);
create type public.promotion_status as enum (
  'pending',
  'approved',
  'rejected',
  'expired'
);
create type public.canonical_report_status as enum (
  'pending',
  'reviewed',
  'resolved',
  'rejected'
);
create type public.category_type as enum ('store', 'listing');
create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  name text,
  phone text,
  email text,
  avatar_media_id uuid,
  status public.profile_status not null default 'active',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.admin_roles (
  user_id uuid primary key references auth.users(id) on delete cascade,
  role text not null check (role = 'admin'),
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  created_by uuid references auth.users(id) on delete set null
);
-- Only non-privileged profile fields are copied from trusted Auth columns or
-- optional user metadata. Role and status are deliberately never copied.
create or replace function public.handle_new_auth_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  insert into public.profiles (id, name, phone, email)
  values (
    new.id,
    nullif(
      btrim(
        coalesce(
          new.raw_user_meta_data ->> 'name',
          new.raw_user_meta_data ->> 'full_name',
          ''
        )
      ),
      ''
    ),
    nullif(
      btrim(
        coalesce(
          new.phone,
          new.raw_user_meta_data ->> 'phone',
          ''
        )
      ),
      ''
    ),
    nullif(lower(btrim(coalesce(new.email, ''))), '')
  )
  on conflict (id) do nothing;

  return new;
end;
$$;
revoke all on function public.handle_new_auth_user_profile() from public;
create trigger on_auth_user_created_create_profile
after insert on auth.users
for each row execute function public.handle_new_auth_user_profile();
-- SECURITY DEFINER avoids recursive admin_roles/profiles RLS evaluation.
-- Every referenced object is schema-qualified and the search path is empty.
create or replace function public.is_active_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select exists (
    select 1
    from public.admin_roles ar
    join public.profiles p on p.id = ar.user_id
    where ar.user_id = (select auth.uid())
      and ar.role = 'admin'
      and ar.is_active = true
      and p.status = 'active'
  );
$$;
revoke all on function public.is_active_admin() from public;
grant execute on function public.is_active_admin()
to authenticated, service_role;
alter table public.profiles enable row level security;
alter table public.admin_roles enable row level security;
create policy "profiles read own"
on public.profiles
for select
to authenticated
using (id = (select auth.uid()));
create policy "active admins read profiles"
on public.profiles
for select
to authenticated
using (public.is_active_admin());
create policy "active users update own profile"
on public.profiles
for update
to authenticated
using (
  id = (select auth.uid())
  and status = 'active'
)
with check (
  id = (select auth.uid())
  and status = 'active'
);
create policy "active admins read admin roles"
on public.admin_roles
for select
to authenticated
using (public.is_active_admin());
-- Remove broad client privileges, then grant only the columns users may edit.
-- No client mutation grant or RLS policy exists for admin_roles.
revoke all on table public.profiles from public, anon, authenticated;
revoke all on table public.admin_roles from public, anon, authenticated;
grant select on table public.profiles to authenticated;
grant update (name, phone, email, avatar_media_id)
on table public.profiles to authenticated;
grant select on table public.admin_roles to authenticated;
grant all on table public.profiles to service_role;
grant all on table public.admin_roles to service_role;
-- Reuse the non-privileged shared trigger function created by migration 0001.
create trigger profiles_set_updated_at
before update on public.profiles
for each row execute function public.set_updated_at();
create trigger admin_roles_set_updated_at
before update on public.admin_roles
for each row execute function public.set_updated_at();
commit;
