create table if not exists public.location_events (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  job_id uuid references public.jobs (id) on delete set null,
  location_id uuid not null references public.locations (id) on delete restrict,
  worker_profile_id uuid not null references public.profiles (id) on delete restrict,
  event_type public.location_event_type not null,
  event_timestamp timestamptz not null,
  metadata jsonb,
  created_at timestamptz not null default timezone('utc', now())
);
