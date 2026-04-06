create index if not exists profiles_organization_id_idx
  on public.profiles (organization_id);
create index if not exists profiles_role_idx
  on public.profiles (role);
create index if not exists profiles_status_idx
  on public.profiles (status);

create index if not exists locations_organization_id_idx
  on public.locations (organization_id);
create index if not exists locations_status_idx
  on public.locations (status);

create index if not exists jobs_organization_id_idx
  on public.jobs (organization_id);
create index if not exists jobs_location_id_idx
  on public.jobs (location_id);
create index if not exists jobs_status_idx
  on public.jobs (status);
create index if not exists jobs_scheduled_start_at_idx
  on public.jobs (scheduled_start_at);
create index if not exists jobs_scheduled_end_at_idx
  on public.jobs (scheduled_end_at);

create index if not exists job_assignments_organization_id_idx
  on public.job_assignments (organization_id);
create index if not exists job_assignments_job_id_idx
  on public.job_assignments (job_id);
create index if not exists job_assignments_worker_profile_id_idx
  on public.job_assignments (worker_profile_id);
create index if not exists job_assignments_assignment_status_idx
  on public.job_assignments (assignment_status);

create index if not exists worker_location_pings_organization_worker_recorded_idx
  on public.worker_location_pings (organization_id, worker_profile_id, recorded_at desc);

create index if not exists location_events_organization_worker_location_job_time_idx
  on public.location_events (
    organization_id,
    worker_profile_id,
    location_id,
    job_id,
    event_timestamp desc
  );
create index if not exists location_events_event_type_idx
  on public.location_events (event_type);

create index if not exists waitlist_leads_email_idx
  on public.waitlist_leads (lower(email));
create index if not exists waitlist_leads_created_at_idx
  on public.waitlist_leads (created_at desc);
