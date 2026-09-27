create function public.prepare_trial_upload(grant_digest text, session_data jsonb, trial_data jsonb, file_data jsonb) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare access jsonb; session_row public.sessions; trial_row public.trials; file_row public.trial_files;
  prior_session public.sessions; prior_trial public.trials; prior_file public.trial_files; task jsonb; definition jsonb; version public.protocol_versions;
begin
  access := public.authorize_participant(grant_digest);
  if access is null then raise exception 'Participant authorization required' using errcode='28000'; end if;
  select * into version from public.protocol_versions where id=(trial_data->>'protocol_version_id')::uuid and status='published';
  session_row := jsonb_populate_record(null::public.sessions, session_data || jsonb_build_object('protocol_id',version.protocol_id,'completed_at',null));
  trial_row := jsonb_populate_record(null::public.trials, trial_data);
  if trial_row.study_id is distinct from (access->>'study_id')::uuid or trial_row.participant_id is distinct from (access->>'participant_id')::uuid
    or trial_row.physical_device_id is distinct from (access->>'physical_device_id')::uuid
    or trial_row.session_id is distinct from session_row.id or trial_row.protocol_version_id is distinct from session_row.protocol_version_id
    or trial_row.participant_id is distinct from session_row.participant_id or trial_row.study_id is distinct from session_row.study_id then
    raise exception 'Trial ownership mismatch' using errcode='42501';
  end if;
  select s into definition from jsonb_array_elements(version.document->'sessions') s where s->>'id'=session_row.session_definition_id::text;
  select t into task from jsonb_array_elements(definition->'tasks') t where t->>'id'=trial_row.task_id::text;
  if task is null or trial_row.prompt is distinct from task->>'prompt' or trial_row.posture is distinct from task->>'posture'
    or trial_row.device_role is distinct from task->>'device_role' or trial_row.repetition < 1
    or not ((trial_row.task_type=task->>'task_type' and trial_row.repetition <= (task->>'repetitions')::integer)
      or (trial_row.task_type='practice' and trial_row.repetition <= coalesce((task->>'practice_repetitions')::integer,0)))
    or (task->>'hand' in ('left','right') and trial_row.hand_used <> task->>'hand') then raise exception 'Trial differs from pinned protocol'; end if;
  insert into public.sessions select (session_row).* on conflict(id) do nothing;
  select * into prior_session from public.sessions where id=session_row.id for update;
  if to_jsonb(prior_session)-'completed_at' <> to_jsonb(session_row)-'completed_at' then raise exception 'Session identity conflict'; end if;
  insert into public.trials select (trial_row).* on conflict(id) do nothing;
  select * into prior_trial from public.trials where id=trial_row.id;
  if to_jsonb(prior_trial) <> to_jsonb(trial_row) then raise exception 'Trial identity conflict'; end if;
  file_row := jsonb_populate_record(null::public.trial_files, file_data || jsonb_build_object(
    'trial_id',trial_row.id,'object_key','study/'||trial_row.study_id||'/'||trial_row.participant_id||'/'||trial_row.session_id||'/'||trial_row.id||'/sensors.csv.gz',
    'sync_status','uploading','uploaded_at',null));
  insert into public.trial_files select (file_row).* on conflict(trial_id) do nothing;
  select * into prior_file from public.trial_files where trial_id=trial_row.id for update;
  if to_jsonb(prior_file)-array['sync_status','uploaded_at'] <> to_jsonb(file_row)-array['sync_status','uploaded_at'] then raise exception 'File identity conflict'; end if;
  return to_jsonb(prior_file);
end $$;
create function public.trial_upload_manifest(grant_digest text, trial_uuid uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare access jsonb; result jsonb;
begin
  access := public.authorize_participant(grant_digest);
  if access is null then raise exception 'Participant authorization required' using errcode='28000'; end if;
  select to_jsonb(f) into result from public.trial_files f join public.trials t on t.id=f.trial_id
    where t.id=trial_uuid and t.participant_id=(access->>'participant_id')::uuid and t.physical_device_id=(access->>'physical_device_id')::uuid;
  if result is null then raise exception 'Trial permission required' using errcode='42501'; end if;
  return result;
end $$;
create function public.finalize_trial_upload(grant_digest text, trial_uuid uuid, verified_sha256 text, verified_size bigint) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare manifest jsonb; result public.trial_files; session_uuid uuid; expected integer; completed integer;
begin
  manifest := public.trial_upload_manifest(grant_digest,trial_uuid);
  if manifest->>'sha256' is distinct from verified_sha256 or (manifest->>'size_bytes')::bigint <> verified_size then raise exception 'Remote verification mismatch'; end if;
  update public.trial_files set sync_status='synced',uploaded_at=coalesce(uploaded_at,now()) where trial_id=trial_uuid returning * into result;
  select session_id into session_uuid from public.trials where id=trial_uuid;
  select sum((t->>'repetitions')::integer + coalesce((t->>'practice_repetitions')::integer,0)) into expected
    from public.sessions s join public.protocol_versions v on v.id=s.protocol_version_id,
      lateral jsonb_array_elements(v.document->'sessions') d,lateral jsonb_array_elements(d->'tasks') t
    where s.id=session_uuid and d->>'id'=s.session_definition_id::text;
  select count(*) into completed from public.trials t join public.trial_files f on f.trial_id=t.id where t.session_id=session_uuid and f.sync_status='synced';
  if completed=expected then update public.sessions set completed_at=coalesce(completed_at,now()) where id=session_uuid; end if;
  return to_jsonb(result);
end $$;
revoke all on function public.prepare_trial_upload(text,jsonb,jsonb,jsonb),public.trial_upload_manifest(text,uuid),public.finalize_trial_upload(text,uuid,text,bigint) from public,anon,authenticated;
grant execute on function public.prepare_trial_upload(text,jsonb,jsonb,jsonb),public.trial_upload_manifest(text,uuid),public.finalize_trial_upload(text,uuid,text,bigint) to service_role;
