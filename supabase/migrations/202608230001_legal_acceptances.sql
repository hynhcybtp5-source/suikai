begin;

create table public.legal_acceptances (
  user_id uuid primary key references auth.users(id) on delete cascade,
  terms_version text not null check (length(btrim(terms_version)) > 0),
  community_guidelines_version text not null check (
    length(btrim(community_guidelines_version)) > 0
  ),
  accepted_at timestamptz not null default now()
);

alter table public.legal_acceptances enable row level security;

create policy "users read own legal acceptance"
on public.legal_acceptances for select to authenticated
using (user_id = (select auth.uid()));

revoke all on table public.legal_acceptances from public, anon, authenticated;
grant select on table public.legal_acceptances to authenticated;
grant all on table public.legal_acceptances to service_role;

create or replace function public.accept_current_legal_versions(
  p_terms_version text,
  p_community_guidelines_version text
)
returns void
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (select auth.uid()) is null then
    raise exception 'Authentication required';
  end if;
  if nullif(btrim(p_terms_version), '') is null
     or nullif(btrim(p_community_guidelines_version), '') is null then
    raise exception 'Legal versions are required';
  end if;

  insert into public.legal_acceptances (
    user_id, terms_version, community_guidelines_version, accepted_at
  ) values (
    (select auth.uid()), btrim(p_terms_version),
    btrim(p_community_guidelines_version), now()
  )
  on conflict (user_id) do update set
    terms_version = excluded.terms_version,
    community_guidelines_version = excluded.community_guidelines_version,
    accepted_at = excluded.accepted_at;
end;
$$;

revoke all on function public.accept_current_legal_versions(text, text)
from public, anon;
grant execute on function public.accept_current_legal_versions(text, text)
to authenticated, service_role;

create or replace function public.record_new_user_legal_acceptance()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  terms_version text := nullif(btrim(new.raw_user_meta_data ->> 'legal_terms_version'), '');
  guidelines_version text := nullif(
    btrim(new.raw_user_meta_data ->> 'legal_community_guidelines_version'), ''
  );
begin
  if new.raw_user_meta_data ->> 'legal_terms_accepted' = 'true'
     and terms_version is not null
     and guidelines_version is not null then
    insert into public.legal_acceptances (
      user_id, terms_version, community_guidelines_version, accepted_at
    ) values (new.id, terms_version, guidelines_version, now())
    on conflict (user_id) do nothing;
  end if;
  return new;
end;
$$;

revoke all on function public.record_new_user_legal_acceptance() from public;

create trigger on_auth_user_created_record_legal_acceptance
after insert on auth.users
for each row execute function public.record_new_user_legal_acceptance();

commit;
