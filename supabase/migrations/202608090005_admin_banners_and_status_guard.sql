begin;

alter table public.stores add column if not exists rejection_reason text;

create table if not exists public.categories (
  id uuid primary key default gen_random_uuid(), name text not null,
  kind text not null check (kind in ('listing','store')), active boolean not null default true,
  sort_order integer not null default 0, created_at timestamptz not null default now()
);

create table if not exists public.banners (
  id uuid primary key default gen_random_uuid(), title text not null,
  image_url text not null, target_url text, placement text not null default 'home',
  active boolean not null default true, sort_order integer not null default 0,
  start_at timestamptz, end_at timestamptz, created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

alter table public.categories enable row level security;
alter table public.banners enable row level security;

create policy "public read active categories" on public.categories for select using (active or public.is_admin());
create policy "admin manage categories" on public.categories for all to authenticated
using (public.is_admin()) with check (public.is_admin());
create policy "public read current banners" on public.banners for select using (
  public.is_admin() or (active and (start_at is null or start_at <= now()) and (end_at is null or end_at >= now()))
);
create policy "admin manage banners" on public.banners for all to authenticated
using (public.is_admin()) with check (public.is_admin());

create or replace function public.guard_store_admin_fields() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  if not public.is_admin() then
    new.status := old.status; new.approved_by := old.approved_by;
    new.approved_at := old.approved_at; new.rejection_reason := old.rejection_reason;
  end if;
  return new;
end; $$;

create trigger stores_guard_admin_fields before update on public.stores
for each row execute function public.guard_store_admin_fields();

create trigger banners_set_updated_at before update on public.banners
for each row execute function public.set_updated_at();

commit;
