-- The fresh baseline grants authenticated users read access to banners only.
-- RLS already restricts mutations to active admins, so grant the table
-- privileges needed by the admin advertisement screen without widening access.
begin;

grant insert, update, delete on table public.banners to authenticated;

commit;
