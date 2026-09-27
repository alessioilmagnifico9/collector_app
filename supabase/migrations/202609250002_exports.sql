create function public.researcher_trial_file(actor uuid, trial_uuid uuid) returns jsonb
language plpgsql stable security definer set search_path = '' as $$
declare result jsonb;
begin
  select to_jsonb(f) into result from public.trial_files f join public.trials t on t.id=f.trial_id
  where t.id=trial_uuid and f.sync_status='synced' and exists(
    select 1 from public.study_members m where m.study_id=t.study_id and m.researcher_id=actor);
  if result is null then raise exception 'Verified file access required' using errcode='42501'; end if;
  return result;
end $$;
revoke all on function public.researcher_trial_file(uuid,uuid) from public,anon,authenticated;
grant execute on function public.researcher_trial_file(uuid,uuid) to service_role;
