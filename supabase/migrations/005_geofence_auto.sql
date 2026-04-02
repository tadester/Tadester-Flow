create or replace function public.handle_geofence_enter()
returns trigger
language plpgsql
as $$
begin
  if new.event_type <> 'enter' then
    return new;
  end if;

  if not exists (
    select 1
    from public.job_time_logs
    where job_id = new.job_id
      and worker_id = new.worker_id
      and exited_at is null
  ) then
    insert into public.job_time_logs (
      job_id,
      worker_id,
      route_id,
      entered_at,
      source
    )
    values (
      new.job_id,
      new.worker_id,
      new.route_id,
      new.event_at,
      'geofence'
    );
  end if;

  update public.jobs
  set status = case
    when status in ('assigned', 'en_route') then 'arrived'
    else status
  end
  where id = new.job_id;

  return new;
end;
$$;

create or replace function public.handle_geofence_exit()
returns trigger
language plpgsql
as $$
declare
  v_log_id uuid;
  v_entered_at timestamptz;
  v_worked_sec integer;
begin
  if new.event_type <> 'exit' then
    return new;
  end if;

  select id, entered_at
  into v_log_id, v_entered_at
  from public.job_time_logs
  where job_id = new.job_id
    and worker_id = new.worker_id
    and exited_at is null
  order by entered_at desc
  limit 1;

  if v_log_id is null then
    return new;
  end if;

  v_worked_sec := greatest(extract(epoch from (new.event_at - v_entered_at))::integer, 0);

  update public.job_time_logs
  set
    exited_at = new.event_at,
    worked_seconds = v_worked_sec,
    billable_seconds = v_worked_sec
  where id = v_log_id;

  update public.jobs
  set status = case
    when status in ('arrived', 'in_progress', 'en_route') then 'completed'
    else status
  end
  where id = new.job_id;

  return new;
end;
$$;

create trigger trg_geofence_enter
after insert on public.geofence_events
for each row execute function public.handle_geofence_enter();

create trigger trg_geofence_exit
after insert on public.geofence_events
for each row execute function public.handle_geofence_exit();