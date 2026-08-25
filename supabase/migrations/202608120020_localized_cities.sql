begin;
create table if not exists public.cities (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  name_th text,
  name_shn text,
  name_en text,
  name_my text,
  is_active boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
alter table public.listings
  add column if not exists city_id uuid references public.cities(id) on delete set null;
create index if not exists listings_city_id_idx on public.listings(city_id);
create index if not exists cities_active_idx on public.cities(is_active);
alter table public.cities enable row level security;
create policy "cities are publicly readable"
on public.cities for select
using (is_active = true or public.is_active_admin());
create policy "admins manage cities"
on public.cities for all
using (public.is_active_admin())
with check (public.is_active_admin());
revoke all on table public.cities from public;
grant select on table public.cities to anon, authenticated;
grant insert, update, delete on table public.cities to authenticated;
grant all on table public.cities to service_role;
commit;
