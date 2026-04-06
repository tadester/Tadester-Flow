-- Phase 2 validation checks for the Tadester Ops MVP schema.
-- Run these queries manually after migrations and seeds to confirm the schema
-- and policies behave as intended.

-- Core counts
select 'organizations' as table_name, count(*) as row_count from public.organizations
union all
select 'profiles', count(*) from public.profiles
union all
select 'locations', count(*) from public.locations
union all
select 'jobs', count(*) from public.jobs
union all
select 'job_assignments', count(*) from public.job_assignments
union all
select 'worker_location_pings', count(*) from public.worker_location_pings
union all
select 'location_events', count(*) from public.location_events
union all
select 'waitlist_leads', count(*) from public.waitlist_leads;

-- Foreign key inventory
select
  tc.table_name,
  tc.constraint_name,
  ccu.table_name as foreign_table_name
from information_schema.table_constraints tc
join information_schema.constraint_column_usage ccu
  on tc.constraint_name = ccu.constraint_name
where tc.constraint_type = 'FOREIGN KEY'
  and tc.table_schema = 'public'
order by tc.table_name, tc.constraint_name;

-- Index inventory
select schemaname, tablename, indexname
from pg_indexes
where schemaname = 'public'
  and tablename in (
    'profiles',
    'locations',
    'jobs',
    'job_assignments',
    'worker_location_pings',
    'location_events',
    'waitlist_leads'
  )
order by tablename, indexname;

-- Sample operational reads
select id, title, status, priority, scheduled_start_at
from public.jobs
order by scheduled_start_at asc;

select worker_profile_id, assignment_status, count(*) as assignment_count
from public.job_assignments
group by worker_profile_id, assignment_status
order by worker_profile_id, assignment_status;

select worker_profile_id, event_type, event_timestamp
from public.location_events
order by event_timestamp desc
limit 10;

select worker_profile_id, recorded_at, latitude, longitude
from public.worker_location_pings
order by recorded_at desc
limit 10;

-- Waitlist lead visibility check (run under anon/authenticated context manually)
-- expected: insert allowed for public, select denied for public

-- RLS helper smoke test (run as authenticated user with matching profile row)
select
  auth.uid() as current_auth_user,
  public.current_user_organization_id() as current_org_id,
  public.current_user_profile_role() as current_role,
  public.is_admin() as is_admin,
  public.is_dispatcher_or_operator() as is_dispatcher_or_operator,
  public.is_field_worker() as is_field_worker;
