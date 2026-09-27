-- Repeated requests retain identity; a new trial UUID cannot inflate completion
-- by recording the same planned task/repetition more often than the protocol.
create function private.check_trial_plan() returns trigger
language plpgsql set search_path = '' as $$
declare pinned public.sessions; task jsonb; quota integer; used integer; dominant text;
begin
  select * into pinned from public.sessions where id=new.session_id for update;
  select t into task from public.protocol_versions v,
    lateral jsonb_array_elements(v.document->'sessions') s,
    lateral jsonb_array_elements(s->'tasks') t
    where v.id=pinned.protocol_version_id and s->>'id'=pinned.session_definition_id::text and t->>'id'=new.task_id::text;
  quota := case when new.task_type=task->>'task_type' and new.repetition between 1 and (task->>'repetitions')::integer then 1 else 0 end
    + case when new.task_type='practice' and new.repetition between 1 and coalesce((task->>'practice_repetitions')::integer,0) then 1 else 0 end;
  select count(*) into used from public.trials where session_id=new.session_id and task_id=new.task_id and task_type=new.task_type and repetition=new.repetition and id<>new.id;
  if quota=0 or used>=quota then raise exception 'Trial exceeds pinned task repetition quota'; end if;
  select dominant_hand into dominant from public.participants where id=new.participant_id;
  if (task->>'hand' in ('left','right') and new.hand_used<>task->>'hand')
    or (task->>'hand'='dominant' and dominant in ('left','right') and new.hand_used<>dominant)
    or (task->>'hand'='non_dominant' and dominant in ('left','right') and new.hand_used=dominant) then
    raise exception 'Trial hand differs from pinned protocol';
  end if;
  return new;
end $$;
create trigger check_trial_plan before insert on public.trials for each row execute function private.check_trial_plan();
create index trials_plan_slot on public.trials(session_id,task_id,task_type,repetition);
