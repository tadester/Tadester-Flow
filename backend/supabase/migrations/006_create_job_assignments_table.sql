create table if not exists public.job_assignments (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  job_id uuid not null references public.jobs (id) on delete cascade,
  worker_profile_id uuid not null references public.profiles (id) on delete restrict,
  assignment_status public.assignment_status not null default 'assigned',
  assigned_at timestamptz not null default timezone('utc', now()),
  assigned_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint job_assignments_unique_worker_job unique (job_id, worker_profile_id)
);
