begin;
-- Public SELECT policies on stores/listings/categories are permissive ORs with
-- admin policies. PostgreSQL may evaluate every policy expression, so anon must
-- be able to call this read-only identity helper; it returns false without UID.
grant execute on function public.is_active_admin() to anon;
commit;
