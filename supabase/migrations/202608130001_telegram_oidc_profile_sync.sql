begin;

alter table public.profiles
  add column if not exists telegram_id text;

create unique index if not exists profiles_telegram_id_unique
on public.profiles (telegram_id)
where telegram_id is not null;

create or replace function public.sync_profile_from_auth_user(p_user_id uuid)
returns public.profiles
language plpgsql
security definer
set search_path = ''
as $$
declare
  auth_user auth.users%rowtype;
  telegram_identity jsonb;
  identity_data jsonb;
  raw_data jsonb;
  given_name text;
  family_name text;
  full_name text;
  phone_value text;
  email_value text;
  telegram_id_value text;
  synced_profile public.profiles%rowtype;
begin
  select *
  into auth_user
  from auth.users
  where id = p_user_id;

  if not found then
    raise exception 'Authenticated user not found';
  end if;

  raw_data := coalesce(auth_user.raw_user_meta_data, '{}'::jsonb);

  select jsonb_build_object(
  'provider', ai.provider,
  'identity_data', ai.identity_data
)
into telegram_identity
from auth.identities ai
where ai.user_id = p_user_id
  and (
    position('telegram' in lower(coalesce(ai.provider, ''))) > 0
    or coalesce(ai.identity_data ->> 'iss', '') = 'https://oauth.telegram.org'
  )
limit 1;

identity_data := coalesce(telegram_identity -> 'identity_data', '{}'::jsonb);

  given_name := nullif(
    btrim(coalesce(raw_data ->> 'given_name', identity_data ->> 'given_name', '')),
    ''
  );
  family_name := nullif(
    btrim(coalesce(raw_data ->> 'family_name', identity_data ->> 'family_name', '')),
    ''
  );
  full_name := nullif(
    btrim(
      coalesce(
        raw_data ->> 'name',
        raw_data ->> 'full_name',
        identity_data ->> 'name',
        identity_data ->> 'full_name',
        concat_ws(' ', given_name, family_name),
        ''
      )
    ),
    ''
  );
  phone_value := nullif(
    btrim(
      coalesce(
        auth_user.phone,
        raw_data ->> 'phone',
        raw_data ->> 'phone_number',
        identity_data ->> 'phone',
        identity_data ->> 'phone_number',
        ''
      )
    ),
    ''
  );
  email_value := nullif(
    lower(
      btrim(
        coalesce(
          auth_user.email,
          raw_data ->> 'email',
          identity_data ->> 'email',
          ''
        )
      )
    ),
    ''
  );
  telegram_id_value := nullif(
    btrim(
      coalesce(
        raw_data ->> 'telegram_id',
        raw_data ->> 'sub',
        identity_data ->> 'telegram_id',
        identity_data ->> 'sub',
        identity_data ->> 'id',
        identity_data ->> 'user_id',
        ''
      )
    ),
    ''
  );

  insert into public.profiles (id, name, phone, email, telegram_id)
  values (
    auth_user.id,
    full_name,
    phone_value,
    email_value,
    telegram_id_value
  )
  on conflict (id) do update
  set name = coalesce(excluded.name, public.profiles.name),
      phone = coalesce(excluded.phone, public.profiles.phone),
      email = coalesce(excluded.email, public.profiles.email),
      telegram_id = coalesce(excluded.telegram_id, public.profiles.telegram_id)
  returning * into synced_profile;

  return synced_profile;
end;
$$;

revoke all on function public.sync_profile_from_auth_user(uuid) from public;
grant execute on function public.sync_profile_from_auth_user(uuid)
to service_role;

create or replace function public.handle_new_auth_user_profile()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  perform public.sync_profile_from_auth_user(new.id);
  return new;
end;
$$;

revoke all on function public.handle_new_auth_user_profile() from public;

drop trigger if exists on_auth_user_created_create_profile on auth.users;
create trigger on_auth_user_created_create_profile
after insert on auth.users
for each row execute function public.handle_new_auth_user_profile();

drop trigger if exists on_auth_user_updated_sync_profile on auth.users;
create trigger on_auth_user_updated_sync_profile
after update of email, phone, raw_user_meta_data on auth.users
for each row execute function public.handle_new_auth_user_profile();

create or replace function public.sync_current_profile_from_auth()
returns public.profiles
language sql
security definer
set search_path = ''
as $$
  select public.sync_profile_from_auth_user((select auth.uid()));
$$;

revoke all on function public.sync_current_profile_from_auth() from public;
grant execute on function public.sync_current_profile_from_auth()
to authenticated, service_role;

commit;
