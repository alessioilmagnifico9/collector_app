-- Use the same session -> file lock order as upload preparation. Without this,
-- concurrent finalizers can both count before the other commits and leave a
-- completely uploaded session permanently incomplete.
create or replace function public.finalize_trial_upload(grant_digest text, trial_uuid uuid, verified_sha256 text, verified_size bigint) returns jsonb
language plpgsql security definer set search_path = '' as $$
declare manifest jsonb; result public.trial_files; session_uuid uuid; expected integer; completed integer;
begin
  manifest := public.trial_upload_manifest(grant_digest,trial_uuid);
  if manifest->>'sha256' is distinct from verified_sha256 or (manifest->>'size_bytes')::bigint <> verified_size then raise exception 'Remote verification mismatch'; end if;
  select s.id into session_uuid from public.sessions s
    join public.trials t on t.session_id=s.id where t.id=trial_uuid for update of s;
  update public.trial_files set sync_status='synced',uploaded_at=coalesce(uploaded_at,now()) where trial_id=trial_uuid returning * into result;
  select sum((t->>'repetitions')::integer + coalesce((t->>'practice_repetitions')::integer,0)) into expected
    from public.sessions s join public.protocol_versions v on v.id=s.protocol_version_id,
      lateral jsonb_array_elements(v.document->'sessions') d,lateral jsonb_array_elements(d->'tasks') t
    where s.id=session_uuid and d->>'id'=s.session_definition_id::text;
  select count(*) into completed from public.trials t join public.trial_files f on f.trial_id=t.id where t.session_id=session_uuid and f.sync_status='synced';
  -- started_at is supplied by an offline phone. Clock skew must not roll back a
  -- verified upload because of the session chronology constraint. This is an
  -- effective completion timestamp; raw durations use native monotonic time.
  if completed=expected then
    update public.sessions set completed_at=coalesce(completed_at,greatest(started_at,clock_timestamp())) where id=session_uuid;
  end if;
  return to_jsonb(result);
end $$;
revoke all on function public.finalize_trial_upload(text,uuid,text,bigint) from public,anon,authenticated;
grant execute on function public.finalize_trial_upload(text,uuid,text,bigint) to service_role;
