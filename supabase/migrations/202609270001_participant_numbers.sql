begin;
-- Block inserts/updates for the entire deterministic backfill and trigger install.
lock table public.participants in access exclusive mode;
alter table public.participants add column display_number integer;
with numbered as (
  select id, row_number() over (partition by study_id order by created_at, id) as n
  from public.participants
)
update public.participants p set display_number=n.n from numbered n where n.id=p.id;
alter table public.participants alter column display_number set not null;
alter table public.participants add constraint participant_number_positive check (display_number > 0);
alter table public.participants add constraint participant_number_unique unique(study_id,display_number);

create table private.participant_counters (
  study_id uuid primary key references public.studies(id),
  last_number integer not null check(last_number > 0)
);
revoke all on private.participant_counters from public, anon, authenticated;
insert into private.participant_counters select study_id,max(display_number) from public.participants group by study_id;

create function private.allocate_participant_number() returns trigger
language plpgsql security definer set search_path='' as $$
begin
  if TG_OP='UPDATE' then
    if new.id is distinct from old.id or new.study_id is distinct from old.study_id
       or new.display_number is distinct from old.display_number then
      raise exception 'Participant identity and display number are immutable';
    end if;
  else
    -- The atomic upsert locks one counter row until commit. Never reuse deleted numbers.
    insert into private.participant_counters as c(study_id,last_number) values(new.study_id,1)
      on conflict(study_id) do update set last_number=c.last_number+1
      returning last_number into new.display_number;
  end if;
  return new;
end $$;
revoke all on function private.allocate_participant_number() from public,anon,authenticated;
create trigger participant_number before insert or update on public.participants
for each row execute function private.allocate_participant_number();
commit;
