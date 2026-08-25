begin;
alter function public.set_updated_at() set search_path = '';
-- Trigger functions are invoked by their triggers and must not be exposed as
-- PostgREST RPCs to application roles.
revoke execute on function public.handle_new_auth_user_profile()
from anon, authenticated, service_role;
revoke execute on function public.guard_store_admin_fields()
from anon, authenticated, service_role;
revoke execute on function public.prepare_store_edit_request()
from anon, authenticated, service_role;
revoke execute on function public.prepare_promotion_request()
from anon, authenticated, service_role;
revoke execute on function public.audit_admin_mutation()
from anon, authenticated, service_role;
-- Identity helpers are needed only by signed-in policies/server operations.
revoke execute on function public.is_active_admin() from anon;
revoke execute on function public.is_active_user() from anon;
grant execute on function public.is_active_admin()
to authenticated, service_role;
grant execute on function public.is_active_user()
to authenticated, service_role;
-- Admin workflow RPCs remain callable by authenticated users because each
-- function verifies is_active_admin() server-side; anonymous calls are denied.
revoke execute on function public.review_store_application(uuid, boolean, text)
from anon;
revoke execute on function public.review_store_edit_request(uuid, boolean, text)
from anon;
revoke execute on function public.review_promotion_request(uuid, boolean, text)
from anon;
revoke execute on function public.review_report(
  uuid,
  public.canonical_report_status,
  text
) from anon;
grant execute on function public.review_store_application(uuid, boolean, text)
to authenticated, service_role;
grant execute on function public.review_store_edit_request(uuid, boolean, text)
to authenticated, service_role;
grant execute on function public.review_promotion_request(uuid, boolean, text)
to authenticated, service_role;
grant execute on function public.review_report(
  uuid,
  public.canonical_report_status,
  text
) to authenticated, service_role;
commit;
