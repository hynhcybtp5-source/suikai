begin;

-- `create_report` runs with an empty search path. pgcrypto is installed in
-- Supabase's `extensions` schema, so the digest calls must be qualified.
create or replace function public.create_report(
  p_reason text,
  p_listing_id uuid default null,
  p_store_id uuid default null,
  p_user_id uuid default null,
  p_device_id text default null
)
returns uuid
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_id uuid := gen_random_uuid();
  v_actor text;
begin
  if nullif(btrim(p_reason), '') is null then
    raise exception 'Report reason required';
  end if;
  if ((p_listing_id is not null)::int + (p_store_id is not null)::int +
      (p_user_id is not null)::int) <> 1 then
    raise exception 'Exactly one report target is required';
  end if;

  v_actor := coalesce(
    (select auth.uid())::text,
    encode(
      extensions.digest(
        coalesce(nullif(btrim(p_device_id), ''), 'anonymous'),
        'sha256'
      ),
      'hex'
    )
  );
  perform public.enforce_action_rate_limit('report', v_actor, interval '60 seconds');

  insert into public.reports(
    id,
    listing_id,
    store_id,
    reported_user_id,
    reporter_id,
    reporter_device_hash,
    reason,
    status,
    workflow_status
  )
  values (
    v_id,
    p_listing_id,
    p_store_id,
    p_user_id,
    (select auth.uid()),
    case
      when p_device_id is null then null
      else encode(extensions.digest(btrim(p_device_id), 'sha256'), 'hex')
    end,
    left(btrim(p_reason), 2000),
    'open',
    'pending'
  );

  insert into public.admin_notifications(type, title, message)
  values ('new_report', 'มีรายงานใหม่', left(btrim(p_reason), 180));

  return v_id;
end;
$$;

revoke all on function public.create_report(text, uuid, uuid, uuid, text)
from public;
grant execute on function public.create_report(text, uuid, uuid, uuid, text)
to anon, authenticated, service_role;

commit;
