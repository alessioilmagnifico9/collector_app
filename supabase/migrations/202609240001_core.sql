-- Researcher access is tenant-scoped. Participant clients use Edge Functions;
-- they receive no direct database grants or Supabase user accounts.
create schema if not exists private;
revoke all on schema private from public;

create table public.researcher_profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  created_at timestamptz not null default now()
);
create table public.studies (
  id uuid primary key default gen_random_uuid(),
  name text not null check (length(trim(name)) between 1 and 200),
  created_by uuid not null references auth.users(id),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);
create table public.study_members (
  id uuid primary key default gen_random_uuid(),
  study_id uuid not null references public.studies(id),
  researcher_id uuid not null references auth.users(id),
  role text not null check (role in ('owner', 'editor', 'viewer')),
  created_at timestamptz not null default now(),
  unique (study_id, researcher_id)
);
create index study_members_researcher on public.study_members(researcher_id, study_id);
create table public.participants (
  id uuid primary key default gen_random_uuid(),
  study_id uuid not null references public.studies(id),
  sex text not null check (sex in ('female', 'male', 'intersex', 'not_reported')),
  dominant_hand text not null check (dominant_hand in ('left', 'right', 'either')),
  created_at timestamptz not null default now(),
  unique (id, study_id)
);
create index participants_study on public.participants(study_id);
create table public.physical_devices (
  id uuid primary key,
  model text not null,
  manufacturer text not null,
  os text not null,
  os_version text not null,
  app_version text not null,
  sensors jsonb not null check (jsonb_typeof(sensors) = 'array'),
  created_at timestamptz not null,
  updated_at timestamptz not null default now()
);
create table public.study_devices (
  id uuid primary key default gen_random_uuid(),
  study_id uuid not null references public.studies(id),
  physical_device_id uuid not null references public.physical_devices(id),
  created_at timestamptz not null default now(),
  unique (study_id, physical_device_id)
);
create index study_devices_device on public.study_devices(physical_device_id);
create table public.protocols (
  id uuid primary key default gen_random_uuid(),
  study_id uuid not null references public.studies(id),
  name text not null check (length(trim(name)) between 1 and 200),
  active_version_id uuid,
  created_at timestamptz not null default now(),
  unique (id, study_id)
);
create index protocols_study on public.protocols(study_id);
create table public.protocol_versions (
  id uuid primary key default gen_random_uuid(),
  protocol_id uuid not null references public.protocols(id),
  version integer not null check (version > 0),
  schema_version integer not null check (schema_version = 1),
  status text not null default 'draft' check (status in ('draft', 'published')),
  document jsonb not null check (jsonb_typeof(document) = 'object'),
  created_at timestamptz not null default now(),
  published_at timestamptz,
  unique (protocol_id, version),
  unique (id, protocol_id),
  check ((status = 'published') = (published_at is not null))
);
alter table public.protocols add constraint active_version_ownership
  foreign key (active_version_id, id) references public.protocol_versions(id, protocol_id);
create table public.sessions (
  id uuid primary key,
  study_id uuid not null references public.studies(id),
  participant_id uuid not null,
  protocol_id uuid not null,
  protocol_version_id uuid not null,
  session_definition_id uuid not null,
  started_at timestamptz not null,
  completed_at timestamptz,
  unique (id, study_id, participant_id, protocol_version_id),
  foreign key (participant_id, study_id) references public.participants(id, study_id),
  foreign key (protocol_id, study_id) references public.protocols(id, study_id),
  foreign key (protocol_version_id, protocol_id) references public.protocol_versions(id, protocol_id),
  check (completed_at is null or completed_at >= started_at)
);
create index sessions_participant on public.sessions(participant_id, started_at);
create index sessions_study on public.sessions(study_id, started_at);
create table public.trials (
  id uuid primary key,
  study_id uuid not null references public.studies(id),
  participant_id uuid not null,
  session_id uuid not null,
  task_id uuid not null,
  prompt text not null,
  repetition integer not null check (repetition > 0),
  hand_used text not null check (hand_used in ('left', 'right')),
  posture text not null check (posture in ('seated', 'standing', 'supine', 'unspecified')),
  task_type text not null check (task_type in ('practice', 'genuine', 'impostor')),
  device_role text not null check (device_role in ('personal', 'phone_a', 'phone_b')),
  physical_device_id uuid not null references public.physical_devices(id),
  app_version text not null,
  protocol_version_id uuid not null,
  schema_version integer not null check (schema_version = 1),
  quality jsonb not null check (jsonb_typeof(quality) = 'object'),
  created_at timestamptz not null,
  foreign key (session_id, study_id, participant_id, protocol_version_id)
    references public.sessions(id, study_id, participant_id, protocol_version_id),
  foreign key (study_id, physical_device_id) references public.study_devices(study_id, physical_device_id)
);
create index trials_session on public.trials(session_id);
create index trials_study on public.trials(study_id, participant_id);
create index trials_device on public.trials(physical_device_id);
create table public.trial_files (
  id uuid primary key,
  trial_id uuid not null unique references public.trials(id),
  object_key text not null unique,
  size_bytes bigint not null check (size_bytes > 0 and size_bytes <= 536870912),
  sha256 text not null check (sha256 ~ '^[0-9a-f]{64}$'),
  content_type text not null check (content_type = 'application/gzip'),
  sync_status text not null check (sync_status in ('local', 'queued', 'uploading', 'synced', 'failed')),
  created_at timestamptz not null,
  uploaded_at timestamptz,
  check ((sync_status = 'synced') = (uploaded_at is not null))
);
create index trial_files_pending on public.trial_files(sync_status) where sync_status <> 'synced';

create function private.study_role(target uuid) returns text
language sql stable security definer set search_path = '' as $$
  select role from public.study_members where study_id = target and researcher_id = (select auth.uid())
$$;
revoke all on function private.study_role(uuid) from public;
grant usage on schema private to authenticated;
grant execute on function private.study_role(uuid) to authenticated;

-- Every table is closed by default, including future service-only writes.
alter table public.researcher_profiles enable row level security;
alter table public.studies enable row level security;
alter table public.study_members enable row level security;
alter table public.participants enable row level security;
alter table public.physical_devices enable row level security;
alter table public.study_devices enable row level security;
alter table public.protocols enable row level security;
alter table public.protocol_versions enable row level security;
alter table public.sessions enable row level security;
alter table public.trials enable row level security;
alter table public.trial_files enable row level security;
revoke all on public.researcher_profiles, public.studies, public.study_members,
  public.participants, public.physical_devices, public.study_devices, public.protocols,
  public.protocol_versions, public.sessions, public.trials, public.trial_files from anon, authenticated;
grant select on public.researcher_profiles, public.studies, public.study_members,
  public.participants, public.physical_devices, public.study_devices, public.protocols,
  public.protocol_versions, public.sessions, public.trials, public.trial_files to authenticated;
grant all on public.researcher_profiles, public.studies, public.study_members,
  public.participants, public.physical_devices, public.study_devices, public.protocols,
  public.protocol_versions, public.sessions, public.trials, public.trial_files to service_role;
grant update(name) on public.studies to authenticated;
grant insert, update on public.protocols, public.protocol_versions to authenticated;

create policy profile_self on public.researcher_profiles for select to authenticated using (id = (select auth.uid()));
create policy studies_read on public.studies for select to authenticated using (private.study_role(id) is not null);
create policy studies_edit on public.studies for update to authenticated
  using (private.study_role(id) in ('owner', 'editor')) with check (private.study_role(id) in ('owner', 'editor'));
create policy members_read on public.study_members for select to authenticated using (private.study_role(study_id) is not null);
create policy participants_read on public.participants for select to authenticated using (private.study_role(study_id) is not null);
create policy study_devices_read on public.study_devices for select to authenticated using (private.study_role(study_id) is not null);
create policy devices_read on public.physical_devices for select to authenticated using (
  exists(select 1 from public.study_devices d where d.physical_device_id = physical_devices.id and private.study_role(d.study_id) is not null)
);
create policy protocols_read on public.protocols for select to authenticated using (private.study_role(study_id) is not null);
create policy protocols_insert on public.protocols for insert to authenticated with check (private.study_role(study_id) in ('owner', 'editor'));
create policy protocols_edit on public.protocols for update to authenticated
  using (private.study_role(study_id) in ('owner', 'editor')) with check (private.study_role(study_id) in ('owner', 'editor'));
create policy versions_read on public.protocol_versions for select to authenticated using (
  exists(select 1 from public.protocols p where p.id = protocol_id and private.study_role(p.study_id) is not null)
);
create policy versions_insert on public.protocol_versions for insert to authenticated with check (
  exists(select 1 from public.protocols p where p.id = protocol_id and private.study_role(p.study_id) in ('owner', 'editor'))
);
create policy versions_edit on public.protocol_versions for update to authenticated using (
  exists(select 1 from public.protocols p where p.id = protocol_id and private.study_role(p.study_id) in ('owner', 'editor'))
) with check (
  exists(select 1 from public.protocols p where p.id = protocol_id and private.study_role(p.study_id) in ('owner', 'editor'))
);
create policy sessions_read on public.sessions for select to authenticated using (private.study_role(study_id) is not null);
create policy trials_read on public.trials for select to authenticated using (private.study_role(study_id) is not null);
create policy files_read on public.trial_files for select to authenticated using (
  exists(select 1 from public.trials t where t.id = trial_id and private.study_role(t.study_id) is not null)
);

create function public.create_study(study_name text) returns uuid
language plpgsql security definer set search_path = '' as $$
declare study_uuid uuid;
begin
  if auth.uid() is null then raise exception 'Researcher authentication required'; end if;
  insert into public.researcher_profiles(id) values(auth.uid()) on conflict do nothing;
  insert into public.studies(name, created_by) values(study_name, auth.uid()) returning id into study_uuid;
  insert into public.study_members(study_id, researcher_id, role) values(study_uuid, auth.uid(), 'owner');
  return study_uuid;
end $$;
revoke all on function public.create_study(text) from public;
grant execute on function public.create_study(text) to authenticated;

create function private.protect_version() returns trigger language plpgsql set search_path = '' as $$
begin
  if TG_OP <> 'INSERT' and old.status = 'published' then raise exception 'Published protocol versions are immutable'; end if;
  if TG_OP = 'DELETE' then return old; end if;
  if TG_OP = 'UPDATE' and (new.id <> old.id or new.protocol_id <> old.protocol_id or new.version <> old.version or new.created_at <> old.created_at) then
    raise exception 'Protocol version identity is immutable';
  end if;
  if new.status = 'published' then
    if new.document->>'schema_version' is distinct from '1'
      or jsonb_typeof(new.document->'sessions') is distinct from 'array'
      or jsonb_array_length(new.document->'sessions') = 0 then
      raise exception 'Published protocol requires schema version 1 and sessions';
    end if;
  end if;
  return new;
end $$;
create trigger protect_version before insert or update or delete on public.protocol_versions
  for each row execute function private.protect_version();

create function private.protect_protocol() returns trigger language plpgsql set search_path = '' as $$
begin
  if TG_OP = 'UPDATE' and (new.id <> old.id or new.study_id <> old.study_id) then raise exception 'Protocol ownership is immutable'; end if;
  if new.active_version_id is not null and not exists (
    select 1 from public.protocol_versions where id = new.active_version_id and protocol_id = new.id and status = 'published'
  ) then raise exception 'Active protocol version must be published'; end if;
  return new;
end $$;
create trigger protect_protocol before insert or update on public.protocols for each row execute function private.protect_protocol();

create function private.check_session() returns trigger language plpgsql set search_path = '' as $$
begin
  if not exists(select 1 from public.protocol_versions v, lateral jsonb_array_elements(v.document->'sessions') s
    where v.id = new.protocol_version_id and v.status = 'published' and s->>'id' = new.session_definition_id::text)
  then raise exception 'Session must use a definition from a published version'; end if;
  if TG_OP = 'UPDATE' and (to_jsonb(new) - 'completed_at') <> (to_jsonb(old) - 'completed_at') then
    raise exception 'Session version and identity are pinned';
  end if;
  return new;
end $$;
create trigger check_session before insert or update on public.sessions for each row execute function private.check_session();

create function private.check_file_key() returns trigger language plpgsql set search_path = '' as $$
declare expected text;
begin
  select 'study/' || study_id || '/' || participant_id || '/' || session_id || '/' || id || '/sensors.csv.gz'
    into expected from public.trials where id = new.trial_id;
  if new.object_key is distinct from expected then raise exception 'Object key must match trial UUID hierarchy'; end if;
  return new;
end $$;
create trigger check_file_key before insert or update on public.trial_files for each row execute function private.check_file_key();
