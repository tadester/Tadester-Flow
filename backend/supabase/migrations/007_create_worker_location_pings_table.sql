create table if not exists public.worker_location_pings (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  worker_profile_id uuid not null references public.profiles (id) on delete restrict,
  latitude numeric(9, 6) not null,
  longitude numeric(9, 6) not null,
  accuracy_meters numeric(8, 2),
  recorded_at timestamptz not null,
  source public.ping_source,
  created_at timestamptz not null default timezone('utc', now()),
  constraint worker_location_pings_latitude_range check (latitude between -90 and 90),
  constraint worker_location_pings_longitude_range check (longitude between -180 and 180),
  constraint worker_location_pings_accuracy_positive check (
    accuracy_meters is null or accuracy_meters >= 0
  )
);
