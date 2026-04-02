alter table public.profiles enable row level security;
alter table public.workers enable row level security;
alter table public.customers enable row level security;
alter table public.service_locations enable row level security;
alter table public.jobs enable row level security;
alter table public.routes enable row level security;
alter table public.route_stops enable row level security;
alter table public.worker_location_pings enable row level security;
alter table public.geofence_events enable row level security;
alter table public.job_time_logs enable row level security;

create policy "profiles self read"
on public.profiles
for select
to authenticated
using (id = auth.uid());

create policy "profiles self update"
on public.profiles
for update
to authenticated
using (id = auth.uid());

create policy "workers self read by profile"
on public.workers
for select
to authenticated
using (profile_id = auth.uid());

create policy "workers self update by profile"
on public.workers
for update
to authenticated
using (profile_id = auth.uid());

create policy "jobs worker can read assigned"
on public.jobs
for select
to authenticated
using (
  assigned_worker_id in (
    select w.id from public.workers w where w.profile_id = auth.uid()
  )
);

create policy "routes worker can read own"
on public.routes
for select
to authenticated
using (
  worker_id in (
    select w.id from public.workers w where w.profile_id = auth.uid()
  )
);

create policy "route stops worker can read own"
on public.route_stops
for select
to authenticated
using (
  route_id in (
    select r.id
    from public.routes r
    join public.workers w on w.id = r.worker_id
    where w.profile_id = auth.uid()
  )
);

create policy "worker pings insert self"
on public.worker_location_pings
for insert
to authenticated
with check (
  worker_id in (
    select w.id from public.workers w where w.profile_id = auth.uid()
  )
);

create policy "geofence insert self"
on public.geofence_events
for insert
to authenticated
with check (
  worker_id in (
    select w.id from public.workers w where w.profile_id = auth.uid()
  )
);

create policy "timelogs read self"
on public.job_time_logs
for select
to authenticated
using (
  worker_id in (
    select w.id from public.workers w where w.profile_id = auth.uid()
  )
);