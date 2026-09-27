-- Recoverable codes remain in the service-role-only credential table.
alter table public.enrollment_credentials add column recoverable_code text
  check (recoverable_code ~ '^[A-Z2-9]{10}$');
drop function public.create_participant_enrollment(uuid,uuid,uuid,text,text,text,text);
create function public.create_participant_enrollment(
  researcher_uuid uuid, study_uuid uuid, protocol_uuid uuid, participant_sex text,
  participant_hand text, code_digest text, token_digest text, enrollment_code text default null
) returns jsonb language plpgsql security definer set search_path = '' as $$
declare person public.participants;
begin
  if not exists(select 1 from public.study_members where study_id = study_uuid and researcher_id = researcher_uuid and role in ('owner','editor'))
    then raise exception 'Study permission required' using errcode='42501'; end if;
  if not exists(select 1 from public.protocols where id=protocol_uuid and study_id=study_uuid and active_version_id is not null)
    then raise exception 'Select a published protocol'; end if;
  insert into public.participants(study_id,sex,dominant_hand) values(study_uuid,participant_sex,participant_hand) returning * into person;
  insert into public.enrollment_credentials(participant_id,protocol_id,code_hash,token_hash,recoverable_code) values(person.id,protocol_uuid,code_digest,token_digest,enrollment_code);
  return to_jsonb(person);
end $$;


create function public.retrieve_participant_enrollment(researcher_uuid uuid, person_uuid uuid, replacement_code text, replacement_digest text)
returns jsonb language plpgsql security definer set search_path = '' as $$
declare credential public.enrollment_credentials;
begin
  if not exists(select 1 from public.participants p join public.study_members m on m.study_id=p.study_id
    where p.id=person_uuid and m.researcher_id=researcher_uuid and m.role in ('owner','editor'))
    then raise exception 'Study permission required' using errcode='42501'; end if;
  select * into credential from public.enrollment_credentials where participant_id=person_uuid and revoked_at is null for update;
  if credential.id is null then raise exception 'Enrollment unavailable'; end if;
  if credential.recoverable_code is null then
    update public.enrollment_credentials set recoverable_code=replacement_code, code_hash=replacement_digest
      where id=credential.id returning * into credential;
  end if;
  return jsonb_build_object('code',credential.recoverable_code);
end $$;
revoke all on function public.create_participant_enrollment(uuid,uuid,uuid,text,text,text,text,text),
  public.retrieve_participant_enrollment(uuid,uuid,text,text) from public, anon, authenticated;
grant execute on function public.create_participant_enrollment(uuid,uuid,uuid,text,text,text,text,text),
  public.retrieve_participant_enrollment(uuid,uuid,text,text) to service_role;
