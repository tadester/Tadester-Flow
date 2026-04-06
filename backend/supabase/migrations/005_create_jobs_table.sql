create table if not exists public.jobs (
  id uuid primary key default gen_random_uuid(),
  organization_id uuid not null references public.organizations (id) on delete restrict,
  location_id uuid not null references public.locations (id) on delete restrict,
  title text not null,
  description text,
  status public.job_status not null default 'draft',
  priority public.job_priority not null default 'medium',
  scheduled_start_at timestamptz not null,
  scheduled_end_at timestamptz not null,
  created_by uuid references public.profiles (id) on delete set null,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint jobs_title_not_blank check (btrim(title) <> ''),
  constraint jobs_schedule_order check (scheduled_end_at >= scheduled_start_at)
);
