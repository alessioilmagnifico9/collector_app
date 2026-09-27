-- Enrollment secrets are hashed; these tables have no client grants.
create table public.enrollment_credentials (
  id uuid primary key default gen_random_uuid(),
  participant_id uuid not null unique references public.participants(id),
  protocol_id uuid not null references public.protocols(id),
  code_hash text not null unique check (code_hash ~ '^[0-9a-f]{64}$'),
  token_hash text not null unique check (token_hash ~ '^[0-9a-f]{64}$'),
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);
create table public.participant_device_grants (
  id uuid primary key default gen_random_uuid(),
  participant_id uuid not null references public.participants(id),
  physical_device_id uuid not null references public.physical_devices(id),
  token_hash text not null unique check (token_hash ~ '^[0-9a-f]{64}$'),
  expires_at timestamptz not null default (now() + interval '180 days'),
  revoked_at timestamptz,
  created_at timestamptz not null default now()
);
create index participant_grants_person on public.participant_device_grants(participant_id, physical_device_id);
create table public.enrollment_rate_limits (
  id uuid primary key default gen_random_uuid(),
  subject text not null unique,
  window_start timestamptz not null,
  attempts integer not null check (attempts > 0)
);
alter table public.enrollment_credentials enable row level security;
alter table public.participant_device_grants enable row level security;
alter table public.enrollment_rate_limits enable row level security;
revoke all on public.enrollment_credentials, public.participant_device_grants, public.enrollment_rate_limits from public, anon, authenticated;
grant all on public.enrollment_credentials, public.participant_device_grants, public.enrollment_rate_limits to service_role;

create function public.consume_enrollment_attempt(subject_hash text, max_attempts integer) returns boolean
language plpgsql security definer set search_path = '' as $$
declare count_now integer;
begin
  if max_attempts < 1 or max_attempts > 1000 then raise exception 'Invalid attempt limit'; end if;
  insert into public.enrollment_rate_limits(subject, window_start, attempts)
    values(subject_hash, date_trunc('minute', now()), 1)
    on conflict (subject) do update set
      attempts = case when public.enrollment_rate_limits.window_start < date_trunc('minute', now()) then 1 else public.enrollment_rate_limits.attempts + 1 end,
      window_start = date_trunc('minute', now())
    returning attempts into count_now;
  return count_now <= max_attempts;
end $$;

create function public.create_participant_enrollment(
  researcher_uuid uuid, study_uuid uuid, protocol_uuid uuid, participant_sex text,
  participant_hand text, code_digest text, token_digest text
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare person public.participants;
begin
  if not exists(select 1 from public.study_members where study_id = study_uuid and researcher_id = researcher_uuid and role in ('owner','editor'))
    then raise exception 'Study permission required' using errcode='42501'; end if;
  if not exists(select 1 from public.protocols where id=protocol_uuid and study_id=study_uuid and active_version_id is not null)
    then raise exception 'Select a published protocol'; end if;
  insert into public.participants(study_id,sex,dominant_hand) values(study_uuid,participant_sex,participant_hand) returning * into person;
  insert into public.enrollment_credentials(participant_id,protocol_id,code_hash,token_hash) values(person.id,protocol_uuid,code_digest,token_digest);
  return to_jsonb(person);
end $$;

create function public.enrollment_context(person_uuid uuid) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('study',to_jsonb(s) - 'created_by' - 'updated_at', 'participant',to_jsonb(p),
    'protocol',to_jsonb(pr) - 'active_version_id', 'version',to_jsonb(v))
  from public.participants p join public.studies s on s.id=p.study_id
  join public.enrollment_credentials e on e.participant_id=p.id and e.revoked_at is null
  join public.protocols pr on pr.id=e.protocol_id
  join public.protocol_versions v on v.id=pr.active_version_id and v.status='published'
  where p.id=person_uuid
$$;

create function public.resolve_enrollment(credential_digest text, device jsonb, grant_digest text) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare person_uuid uuid; device_uuid uuid; context jsonb;
begin
  select participant_id into person_uuid from public.enrollment_credentials
    where (code_hash=credential_digest or token_hash=credential_digest) and revoked_at is null;
  if person_uuid is null then raise exception 'Enrollment unavailable' using errcode='28000'; end if;
  context := public.enrollment_context(person_uuid);
  if context is null then raise exception 'Enrollment unavailable' using errcode='28000'; end if;
  device_uuid := (device->>'id')::uuid;
  insert into public.physical_devices(id,model,manufacturer,os,os_version,app_version,sensors,created_at)
    values(device_uuid,device->>'model',device->>'manufacturer',device->>'os',device->>'os_version',device->>'app_version',device->'sensors',(device->>'created_at')::timestamptz)
    on conflict(id) do nothing;
  insert into public.study_devices(study_id,physical_device_id) values((context->'study'->>'id')::uuid,device_uuid) on conflict do nothing;
  insert into public.participant_device_grants(participant_id,physical_device_id,token_hash) values(person_uuid,device_uuid,grant_digest);
  return context;
end $$;

create function public.authorize_participant(grant_digest text) returns jsonb
language sql stable security definer set search_path = '' as $$
  select jsonb_build_object('participant_id',g.participant_id,'physical_device_id',g.physical_device_id,'study_id',p.study_id)
  from public.participant_device_grants g join public.participants p on p.id=g.participant_id
  join public.enrollment_credentials e on e.participant_id=p.id and e.revoked_at is null
  where g.token_hash=grant_digest and g.revoked_at is null and g.expires_at>now()
$$;
revoke all on function public.consume_enrollment_attempt(text,integer),
  public.create_participant_enrollment(uuid,uuid,uuid,text,text,text,text),
  public.enrollment_context(uuid), public.resolve_enrollment(text,jsonb,text), public.authorize_participant(text) from public, anon, authenticated;
grant execute on function public.consume_enrollment_attempt(text,integer),
  public.create_participant_enrollment(uuid,uuid,uuid,text,text,text,text),
  public.enrollment_context(uuid), public.resolve_enrollment(text,jsonb,text), public.authorize_participant(text) to service_role;
