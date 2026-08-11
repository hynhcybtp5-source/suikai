begin;

-- Fixed UUIDs are transaction-local test fixtures; the final rollback leaves
-- staging unchanged.
insert into auth.users (id, email, raw_user_meta_data)
values
  ('00000000-0000-4000-8000-000000000101', 'normal@staging.test', '{}'::jsonb),
  ('00000000-0000-4000-8000-000000000102', 'suspended@staging.test', '{}'::jsonb),
  (
    '00000000-0000-4000-8000-000000000103',
    'admin@staging.test',
    '{"name":"Staging Admin","role":"admin","status":"suspended"}'::jsonb
  );

do $$
begin
  if (select count(*) from public.profiles
      where id::text like '00000000-0000-4000-8000-00000000010%') <> 3 then
    raise exception 'Auth trigger did not create all profiles';
  end if;

  if (select status from public.profiles
      where id = '00000000-0000-4000-8000-000000000103') <> 'active' then
    raise exception 'Auth metadata changed protected profile status';
  end if;

  if exists (
    select 1 from public.admin_roles
    where user_id = '00000000-0000-4000-8000-000000000103'
  ) then
    raise exception 'Auth metadata created an admin role';
  end if;
end;
$$;

update public.profiles
set status = 'suspended'
where id = '00000000-0000-4000-8000-000000000102';

insert into public.admin_roles (user_id, role)
values ('00000000-0000-4000-8000-000000000103', 'admin');

-- Guest has neither table privilege nor an RLS path to identity data.
set local role anon;
select set_config('request.jwt.claim.sub', '', true);
do $$
declare
  profiles_denied boolean := false;
  roles_denied boolean := false;
begin
  begin
    perform 1 from public.profiles;
  exception when insufficient_privilege then
    profiles_denied := true;
  end;

  begin
    perform 1 from public.admin_roles;
  exception when insufficient_privilege then
    roles_denied := true;
  end;

  if not profiles_denied or not roles_denied then
    raise exception 'Guest can read protected identity data';
  end if;
end;
$$;
reset role;

-- A normal user sees and edits only their own non-privileged fields.
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000101',
  true
);
set local role authenticated;
do $$
declare
  affected integer;
  protected_update_denied boolean := false;
begin
  if (select count(*) from public.profiles) <> 1 then
    raise exception 'Normal user profile SELECT scope is incorrect';
  end if;

  if public.is_active_admin() then
    raise exception 'Normal user received admin privilege';
  end if;

  update public.profiles
  set name = 'Normal Updated'
  where id = auth.uid();
  get diagnostics affected = row_count;
  if affected <> 1 then
    raise exception 'Normal user could not update own profile';
  end if;

  begin
    update public.profiles set status = 'suspended' where id = auth.uid();
  exception when insufficient_privilege then
    protected_update_denied := true;
  end;
  if not protected_update_denied then
    raise exception 'Normal user changed protected profile status';
  end if;

  if (select count(*) from public.admin_roles) <> 0 then
    raise exception 'Normal user can read admin roles';
  end if;
end;
$$;
reset role;

-- Suspended users retain own-profile read access but cannot update it.
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000102',
  true
);
set local role authenticated;
do $$
declare
  affected integer;
begin
  if (select count(*) from public.profiles) <> 1 then
    raise exception 'Suspended user cannot read own profile';
  end if;

  update public.profiles
  set name = 'Must Not Change'
  where id = auth.uid();
  get diagnostics affected = row_count;
  if affected <> 0 then
    raise exception 'Suspended user updated own profile';
  end if;
end;
$$;
reset role;

-- Active admin can read identity data, but the client role cannot mutate roles.
select set_config(
  'request.jwt.claim.sub',
  '00000000-0000-4000-8000-000000000103',
  true
);
set local role authenticated;
do $$
declare
  role_mutation_denied boolean := false;
begin
  if not public.is_active_admin() then
    raise exception 'Active admin check failed';
  end if;

  if (select count(*) from public.profiles) <> 3 then
    raise exception 'Admin cannot read profiles';
  end if;

  if (select count(*) from public.admin_roles) <> 1 then
    raise exception 'Admin cannot read admin roles';
  end if;

  begin
    update public.admin_roles set is_active = false where user_id = auth.uid();
  exception when insufficient_privilege then
    role_mutation_denied := true;
  end;
  if not role_mutation_denied then
    raise exception 'Authenticated client mutated admin_roles';
  end if;
end;
$$;
reset role;

rollback;
