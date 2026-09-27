-- One statement snapshot; security invoker preserves all existing RLS boundaries.
-- Explicit table allowlist excludes enrollment secrets, grants and auth profiles.
create function public.study_dataset(study_uuid uuid) returns jsonb
language plpgsql stable security invoker set search_path = '' as $$
begin
  if private.study_role(study_uuid) is null then
    raise exception 'Study permission required' using errcode='42501';
  end if;
  return jsonb_build_object(
    'export_schema_version', 1,
    'study', (select jsonb_build_object('id',id,'name',name,'created_at',created_at) from public.studies where id=study_uuid),
    'participants', coalesce((select jsonb_agg(to_jsonb(p) order by p.id) from public.participants p where p.study_id=study_uuid), '[]'::jsonb),
    'devices', coalesce((select jsonb_agg(to_jsonb(d) order by d.id) from public.physical_devices d where exists(select 1 from public.study_devices sd where sd.study_id=study_uuid and sd.physical_device_id=d.id)), '[]'::jsonb),
    'protocols', coalesce((select jsonb_agg(to_jsonb(p) order by p.id) from public.protocols p where p.study_id=study_uuid), '[]'::jsonb),
    'protocol_versions', coalesce((select jsonb_agg(to_jsonb(v) order by v.id) from public.protocol_versions v join public.protocols p on p.id=v.protocol_id where p.study_id=study_uuid), '[]'::jsonb),
    'sessions', coalesce((select jsonb_agg(to_jsonb(s) order by s.id) from public.sessions s where s.study_id=study_uuid), '[]'::jsonb),
    'trials', coalesce((select jsonb_agg(to_jsonb(t) order by t.id) from public.trials t where t.study_id=study_uuid), '[]'::jsonb),
    'trial_files', coalesce((select jsonb_agg(to_jsonb(f) order by f.id) from public.trial_files f join public.trials t on t.id=f.trial_id where t.study_id=study_uuid), '[]'::jsonb)
  );
end $$;
revoke all on function public.study_dataset(uuid) from public,anon;
grant execute on function public.study_dataset(uuid) to authenticated;

create function public.fail_trial_upload(grant_digest text, trial_uuid uuid) returns void
language plpgsql security definer set search_path = '' as $$
begin
  perform public.trial_upload_manifest(grant_digest,trial_uuid);
  update public.trial_files set sync_status='failed' where trial_id=trial_uuid and sync_status <> 'synced';
end $$;
revoke all on function public.fail_trial_upload(text,uuid) from public,anon,authenticated;
grant execute on function public.fail_trial_upload(text,uuid) to service_role;
