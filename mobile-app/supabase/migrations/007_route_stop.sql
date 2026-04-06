create or replace function public.assign_job_to_route(
  p_job_id uuid,
  p_route_id uuid,
  p_stop_order integer
)
returns void
language plpgsql
as $$
declare
  v_route_worker uuid;
  v_route_stop_id uuid;
begin
  select worker_id into v_route_worker
  from public.routes
  where id = p_route_id;

  insert into public.route_stops (
    route_id, job_id, stop_order
  )
  values (
    p_route_id, p_job_id, p_stop_order
  )
  returning id into v_route_stop_id;

  update public.jobs
  set
    assigned_worker_id = v_route_worker,
    route_stop_id = v_route_stop_id,
    status = 'assigned'
  where id = p_job_id;
end;
$$;