create table public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  full_name text,
  phone text,
  role text not null check (role in ('owner','dispatcher','manager','worker')),
  created_at timestamptz not null default now()
);

create table public.workers (
  id uuid primary key default gen_random_uuid(),
  profile_id uuid not null unique references public.profiles(id) on delete cascade,
  employee_code text unique,
  skill_tags text[] not null default '{}',
  is_active boolean not null default true,
  home_base geography(point, 4326),
  shift_start time,
  shift_end time,
  max_jobs_per_day integer,
  created_at timestamptz not null default now()
);

create table public.customers (
  id uuid primary key default gen_random_uuid(),
  name text not null,
  phone text,
  email text,
  notes text,
  created_at timestamptz not null default now()
);

create table public.service_locations (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete cascade,
  label text,
  address_line1 text not null,
  address_line2 text,
  city text,
  region text,
  postal_code text,
  country text default 'Canada',
  lat double precision not null,
  lng double precision not null,
  point geography(point, 4326) not null,
  geofence_radius_m integer not null default 50,
  created_at timestamptz not null default now()
);

create table public.jobs (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.customers(id) on delete restrict,
  service_location_id uuid not null references public.service_locations(id) on delete restrict,
  service_type text not null check (service_type in ('landscaping','snow_removal','door_knocking','inspection','other')),
  status text not null default 'unassigned' check (
    status in ('unassigned','assigned','en_route','arrived','in_progress','completed','canceled','failed')
  ),
  priority integer not null default 3 check (priority between 1 and 5),
  scheduled_date date,
  time_window_start timestamptz,
  time_window_end timestamptz,
  estimated_duration_min integer not null default 30,
  required_skill_tags text[] not null default '{}',
  assigned_worker_id uuid references public.workers(id) on delete set null,
  route_stop_id uuid,
  cancellation_reason text,
  metadata jsonb not null default '{}',
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table public.routes (
  id uuid primary key default gen_random_uuid(),
  route_date date not null,
  worker_id uuid not null references public.workers(id) on delete cascade,
  status text not null default 'draft' check (
    status in ('draft','published','active','completed','canceled')
  ),
  start_location geography(point, 4326),
  end_location geography(point, 4326),
  optimization_provider text,
  optimization_payload jsonb,
  total_distance_m integer,
  total_duration_sec integer,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  unique (route_date, worker_id)
);

create table public.route_stops (
  id uuid primary key default gen_random_uuid(),
  route_id uuid not null references public.routes(id) on delete cascade,
  job_id uuid not null unique references public.jobs(id) on delete cascade,
  stop_order integer not null,
  planned_arrival timestamptz,
  planned_departure timestamptz,
  planned_distance_from_prev_m integer,
  planned_drive_sec_from_prev integer,
  actual_arrival timestamptz,
  actual_departure timestamptz,
  stop_status text not null default 'planned' check (
    stop_status in ('planned','skipped','arrived','completed','failed','canceled')
  ),
  unique (route_id, stop_order)
);

alter table public.jobs
  add constraint fk_jobs_route_stop
  foreign key (route_stop_id) references public.route_stops(id) on delete set null;

create table public.worker_location_pings (
  id bigserial primary key,
  worker_id uuid not null references public.workers(id) on delete cascade,
  route_id uuid references public.routes(id) on delete set null,
  recorded_at timestamptz not null default now(),
  lat double precision not null,
  lng double precision not null,
  accuracy_m double precision,
  speed_mps double precision,
  heading_deg double precision,
  battery_pct double precision,
  point geography(point, 4326) not null
);

create table public.geofence_events (
  id bigserial primary key,
  worker_id uuid not null references public.workers(id) on delete cascade,
  job_id uuid not null references public.jobs(id) on delete cascade,
  route_id uuid references public.routes(id) on delete set null,
  event_type text not null check (event_type in ('enter','exit')),
  source text not null default 'gps' check (source in ('gps','manual','system')),
  event_at timestamptz not null default now(),
  lat double precision not null,
  lng double precision not null,
  point geography(point, 4326) not null,
  accuracy_m double precision,
  dwell_seconds integer,
  metadata jsonb not null default '{}'
);

create table public.job_time_logs (
  id uuid primary key default gen_random_uuid(),
  job_id uuid not null references public.jobs(id) on delete cascade,
  worker_id uuid not null references public.workers(id) on delete cascade,
  route_id uuid references public.routes(id) on delete set null,
  entered_at timestamptz not null,
  exited_at timestamptz,
  worked_seconds integer,
  billable_seconds integer,
  source text not null default 'geofence',
  created_at timestamptz not null default now()
);

create table public.dispatch_events (
  id bigserial primary key,
  event_type text not null,
  entity_type text not null,
  entity_id uuid,
  payload jsonb not null default '{}',
  created_at timestamptz not null default now()
);