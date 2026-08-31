begin;

-- Keep the pre-existing moderation RPCs and audit table.  This wrapper makes
-- the report that initiated an action part of the existing audit trail.
create or replace function public.admin_act_on_report_target(
  p_report_id uuid,
  p_action text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
declare
  target_kind text;
  target_uuid uuid;
begin
  if not public.is_active_admin() then
    raise exception 'Active admin required';
  end if;

  select case
      when r.listing_id is not null then 'listing'
      when r.store_id is not null then 'store'
      when r.reported_user_id is not null then 'user'
    end,
    coalesce(r.listing_id, r.store_id, r.reported_user_id)
  into target_kind, target_uuid
  from public.reports r
  where r.id = p_report_id
  for update;

  if target_uuid is null then
    raise exception 'Report target not found';
  end if;

  if target_kind = 'listing' and p_action = 'listing_hide' then
    perform public.admin_moderate_listing(target_uuid, 'hidden');
  elsif target_kind = 'listing' and p_action = 'listing_restore' then
    perform public.admin_moderate_listing(target_uuid, 'visible');
  elsif target_kind = 'listing' and p_action = 'listing_delete' then
    -- Existing moderation RPC uses soft delete; reports retain their target id.
    perform public.admin_moderate_listing(target_uuid, 'deleted');
  elsif target_kind = 'store' and p_action = 'store_suspend' then
    perform public.admin_set_store_status(target_uuid, 'suspended');
  elsif target_kind = 'store' and p_action = 'store_restore' then
    perform public.admin_set_store_status(target_uuid, 'active');
  elsif target_kind = 'user' and p_action = 'user_suspend' then
    perform public.admin_set_profile_status(target_uuid, 'suspended');
  elsif target_kind = 'user' and p_action = 'user_restore' then
    perform public.admin_set_profile_status(target_uuid, 'active');
  else
    raise exception 'Invalid report target action';
  end if;

  insert into public.admin_audit_logs (
    actor_id, action, target_type, target_id, after_data
  ) values (
    (select auth.uid()),
    p_action,
    target_kind,
    target_uuid::text,
    jsonb_build_object('report_id', p_report_id)
  );
end;
$$;

revoke all on function public.admin_act_on_report_target(uuid, text) from public;
grant execute on function public.admin_act_on_report_target(uuid, text)
to authenticated, service_role;

commit;
