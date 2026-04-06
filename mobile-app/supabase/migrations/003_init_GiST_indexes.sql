create index if not exists idx_workers_home_base_gist
  on public.workers using gist (home_base);

create index if not exists idx_service_locations_point_gist
  on public.service_locations using gist (point);

create index if not exists idx_worker_location_pings_point_gist
  on public.worker_location_pings using gist (point);

create index if not exists idx_geofence_events_point_gist
  on public.geofence_events using gist (point);

create index if not exists idx_jobs_assigned_worker
  on public.jobs (assigned_worker_id);

create index if not exists idx_jobs_status_date
  on public.jobs (status, scheduled_date);

create index if not exists idx_route_stops_route_order
  on public.route_stops (route_id, stop_order);

create index if not exists idx_geofence_events_job_worker_time
  on public.geofence_events (job_id, worker_id, event_at);

create index if not exists idx_job_time_logs_job_worker
  on public.job_time_logs (job_id, worker_id);