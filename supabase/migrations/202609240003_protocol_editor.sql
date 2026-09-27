create function private.protocol_text(value jsonb, label text, optional boolean default false) returns void
language plpgsql immutable set search_path = '' as $$
begin
  if optional and (value is null or value='null'::jsonb) then return; end if;
  if jsonb_typeof(value) is distinct from 'string' or length(trim(value #>> '{}')) = 0 then
    raise exception '% must be nonempty text', label;
  end if;
end $$;
create function private.validate_protocol(doc jsonb) returns void
language plpgsql immutable set search_path = '' as $$
declare s jsonb; t jsonb; seen_sessions text[] := '{}'; seen_tasks text[]; total integer; n integer; practice integer;
  uuid_pattern text := '^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$';
begin
  if jsonb_typeof(doc) is distinct from 'object' or doc - array['schema_version','requested_hz','sessions','order_metadata'] <> '{}'::jsonb then raise exception 'Unknown protocol fields'; end if;
  if doc->'schema_version' is distinct from '1'::jsonb then raise exception 'schema_version must be 1'; end if;
  if jsonb_typeof(doc->'requested_hz') is distinct from 'number' or (doc->>'requested_hz')::numeric not between 1 and 200 then raise exception 'requested_hz must be 1-200'; end if;
  if doc ? 'order_metadata' and jsonb_typeof(doc->'order_metadata') not in ('object','null') then raise exception 'order_metadata must be an object'; end if;
  if jsonb_typeof(doc->'sessions') is distinct from 'array' then raise exception 'sessions must be an array'; end if;
  if jsonb_array_length(doc->'sessions') not between 1 and 100 then raise exception 'sessions must contain 1-100 sessions'; end if;
  for s in select value from jsonb_array_elements(doc->'sessions') loop
    if jsonb_typeof(s) is distinct from 'object' or s - array['id','title','instructions','tasks'] <> '{}'::jsonb then raise exception 'Unknown session fields'; end if;
    if coalesce(s->>'id','') !~ uuid_pattern or s->>'id'=any(seen_sessions) then raise exception 'Session IDs must be unique UUIDs'; end if;
    seen_sessions := array_append(seen_sessions,s->>'id');
    perform private.protocol_text(s->'title','Session title');
    perform private.protocol_text(s->'instructions','Session instructions',true);
    if jsonb_typeof(s->'tasks') is distinct from 'array' then raise exception 'tasks must be an array'; end if;
    if jsonb_array_length(s->'tasks')=0 then raise exception 'Session must contain tasks'; end if;
    seen_tasks := '{}'; total := 0;
    for t in select value from jsonb_array_elements(s->'tasks') loop
      if jsonb_typeof(t) is distinct from 'object' or t - array['id','prompt','repetitions','posture','hand','device_role','task_type','preparation','practice_repetitions','duration_seconds'] <> '{}'::jsonb then raise exception 'Unknown task fields'; end if;
      if coalesce(t->>'id','') !~ uuid_pattern or t->>'id'=any(seen_tasks) then raise exception 'Task IDs must be unique UUIDs within a session'; end if;
      seen_tasks := array_append(seen_tasks,t->>'id');
      perform private.protocol_text(t->'prompt','Task prompt');
      perform private.protocol_text(t->'preparation','Task preparation',true);
      if jsonb_typeof(t->'repetitions') is distinct from 'number' or coalesce(t->>'repetitions','') !~ '^[0-9]+$' then raise exception 'repetitions must be an integer'; end if;
      n := (t->>'repetitions')::integer;
      if n not between 1 and 1000 then raise exception 'repetitions must be 1-1000'; end if;
      practice := 0;
      if t ? 'practice_repetitions' and t->'practice_repetitions' <> 'null'::jsonb then
        if jsonb_typeof(t->'practice_repetitions') is distinct from 'number' or t->>'practice_repetitions' !~ '^[0-9]+$' then raise exception 'practice_repetitions must be an integer'; end if;
        practice := (t->>'practice_repetitions')::integer;
      end if;
      if practice not between 0 and 100 then raise exception 'practice_repetitions must be 0-100'; end if;
      total := total + n + practice;
      if total > 10000 then raise exception 'A session cannot exceed 10000 trials'; end if;
      if coalesce(t->>'posture','') not in ('seated','standing','supine','unspecified') then raise exception 'Invalid posture'; end if;
      if coalesce(t->>'hand','') not in ('left','right','either','dominant','non_dominant') then raise exception 'Invalid hand'; end if;
      if coalesce(t->>'device_role','') not in ('personal','phone_a','phone_b') then raise exception 'Invalid device_role'; end if;
      if coalesce(t->>'task_type','') not in ('practice','genuine','impostor') then raise exception 'Invalid task_type'; end if;
      if t ? 'duration_seconds' and t->'duration_seconds' <> 'null'::jsonb then
        if jsonb_typeof(t->'duration_seconds') is distinct from 'number' or (t->>'duration_seconds')::numeric not between 0.1 and 600 then raise exception 'duration_seconds must be 0.1-600'; end if;
      end if;
    end loop;
  end loop;
end $$;
create or replace function private.protect_version() returns trigger language plpgsql set search_path = '' as $$
begin
  if TG_OP <> 'INSERT' and old.status = 'published' then raise exception 'Published protocol versions are immutable'; end if;
  if TG_OP = 'DELETE' then return old; end if;
  if TG_OP = 'UPDATE' and (new.id <> old.id or new.protocol_id <> old.protocol_id or new.version <> old.version or new.created_at <> old.created_at) then raise exception 'Protocol version identity is immutable'; end if;
  if new.status = 'published' then perform private.validate_protocol(new.document); end if;
  return new;
end $$;

create function public.create_protocol_draft(study_uuid uuid, protocol_name text, document jsonb, source_uuid uuid default null) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare protocol_uuid uuid; next_version integer; created public.protocol_versions;
begin
  if coalesce(private.study_role(study_uuid),'') not in ('owner','editor') then raise exception 'Study permission required' using errcode='42501'; end if;
  if source_uuid is null then
    insert into public.protocols(study_id,name) values(study_uuid,protocol_name) returning id into protocol_uuid;
    next_version := 1;
  else
    select p.id into protocol_uuid from public.protocols p join public.protocol_versions v on v.protocol_id=p.id where v.id=source_uuid and p.study_id=study_uuid for update of p;
    if protocol_uuid is null then raise exception 'Source protocol not found'; end if;
    select coalesce(max(version),0)+1 into next_version from public.protocol_versions where protocol_id=protocol_uuid;
  end if;
  insert into public.protocol_versions(protocol_id,version,schema_version,document) values(protocol_uuid,next_version,1,document) returning * into created;
  return to_jsonb(created);
end $$;
create function public.save_protocol_draft(version_uuid uuid, expected_document jsonb, document jsonb, publish boolean default false) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare existing public.protocol_versions; study_uuid uuid;
begin
  select * into existing from public.protocol_versions where id=version_uuid for update;
  select study_id into study_uuid from public.protocols where id=existing.protocol_id;
  if coalesce(private.study_role(study_uuid),'') not in ('owner','editor') then raise exception 'Study permission required' using errcode='42501'; end if;
  if existing.status <> 'draft' then raise exception 'Published versions are immutable'; end if;
  if existing.document <> expected_document then raise exception 'Draft changed in another editor; reload before saving' using errcode='40001'; end if;
  if publish then perform private.validate_protocol(document); end if;
  update public.protocol_versions set document=save_protocol_draft.document, status=case when publish then 'published' else 'draft' end,
    published_at=case when publish then now() else null end where id=version_uuid returning * into existing;
  if publish then update public.protocols set active_version_id=version_uuid where id=existing.protocol_id; end if;
  return to_jsonb(existing);
end $$;
revoke all on function public.create_protocol_draft(uuid,text,jsonb,uuid), public.save_protocol_draft(uuid,jsonb,jsonb,boolean) from public;
grant execute on function public.create_protocol_draft(uuid,text,jsonb,uuid), public.save_protocol_draft(uuid,jsonb,jsonb,boolean) to authenticated;
revoke all on function private.protocol_text(jsonb,text,boolean),private.validate_protocol(jsonb) from public;
-- Pure validation helpers may be called by the invoker-rights publication trigger.
grant execute on function private.protocol_text(jsonb,text,boolean),private.validate_protocol(jsonb) to authenticated, service_role;
