drop policy if exists "organizations_select_own" on public.organizations;
create policy "organizations_select_own"
on public.organizations
for select
to authenticated
using (id = public.current_user_organization_id());

drop policy if exists "organizations_admin_update" on public.organizations;
create policy "organizations_admin_update"
on public.organizations
for update
to authenticated
using (
  public.is_admin()
  and id = public.current_user_organization_id()
)
with check (
  public.is_admin()
  and id = public.current_user_organization_id()
);

drop policy if exists "profiles_staff_select_org" on public.profiles;
create policy "profiles_staff_select_org"
on public.profiles
for select
to authenticated
using (
  organization_id = public.current_user_organization_id()
  and (
    public.is_admin()
    or public.is_dispatcher_or_operator()
    or id = auth.uid()
  )
);

drop policy if exists "profiles_staff_manage_org" on public.profiles;
create policy "profiles_staff_manage_org"
on public.profiles
for all
to authenticated
using (
  organization_id = public.current_user_organization_id()
  and (
    public.is_admin()
    or public.is_dispatcher_or_operator()
  )
)
with check (
  organization_id = public.current_user_organization_id()
  and (
    public.is_admin()
    or public.is_dispatcher_or_operator()
  )
);

drop policy if exists "locations_staff_manage_org" on public.locations;
create policy "locations_staff_manage_org"
on public.locations
for all
to authenticated
using (
  organization_id = public.current_user_organization_id()
  and (
    public.is_admin()
    or public.is_dispatcher_or_operator()
  )
)
with check (
  organization_id = public.current_user_organization_id()
  and (
    public.is_admin()
    or public.is_dispatcher_or_operator()
  )
);

drop policy if exists "locations_worker_select_assigned" on public.locations;
create policy "locations_worker_select_assigned"
on public.locations
for select
to authenticated
using (
  public.is_field_worker()
  and exists (
    select 1
    from public.job_assignments ja
    join public.jobs j on j.id = ja.job_id
    where ja.worker_profile_id = auth.uid()
      and ja.organization_id = locations.organization_id
      and j.location_id = locations.id
  )
);

drop policy if exists "jobs_staff_manage_org" on public.jobs;
create policy "jobs_staff_manage_org"
on public.jobs
for all
to authenticated
using (
  organization_id = public.current_user_organization_id()
  and (
    public.is_admin()
    or public.is_dispatcher_or_operator()
  )
)
with check (
  organization_id = public.current_user_organization_id()
  and (
    public.is_admin()
    or public.is_dispatcher_or_operator()
  )
);

drop policy if exists "jobs_worker_select_assigned" on public.jobs;
create policy "jobs_worker_select_assigned"
on public.jobs
for select
to authenticated
using (
  public.is_field_worker()
  and exists (
    select 1
    from public.job_assignments ja
    where ja.job_id = jobs.id
      and ja.worker_profile_id = auth.uid()
  )
);

drop policy if exists "job_assignments_staff_manage_org" on public.job_assignments;
create policy "job_assignments_staff_manage_org"
on public.job_assignments
for all
to authenticated
using (
  organization_id = public.current_user_organization_id()
  and (
    public.is_admin()
    or public.is_dispatcher_or_operator()
  )
)
with check (
  organization_id = public.current_user_organization_id()
  and (
    public.is_admin()
    or public.is_dispatcher_or_operator()
  )
);

drop policy if exists "job_assignments_worker_select_own" on public.job_assignments;
create policy "job_assignments_worker_select_own"
on public.job_assignments
for select
to authenticated
using (
  public.is_field_worker()
  and worker_profile_id = auth.uid()
);

drop policy if exists "worker_location_pings_staff_read_org" on public.worker_location_pings;
create policy "worker_location_pings_staff_read_org"
on public.worker_location_pings
for select
to authenticated
using (
  organization_id = public.current_user_organization_id()
  and (
    public.is_admin()
    or public.is_dispatcher_or_operator()
  )
);

drop policy if exists "worker_location_pings_worker_read_own" on public.worker_location_pings;
create policy "worker_location_pings_worker_read_own"
on public.worker_location_pings
for select
to authenticated
using (
  public.is_field_worker()
  and worker_profile_id = auth.uid()
);

drop policy if exists "worker_location_pings_worker_insert_own" on public.worker_location_pings;
create policy "worker_location_pings_worker_insert_own"
on public.worker_location_pings
for insert
to authenticated
with check (
  organization_id = public.current_user_organization_id()
  and worker_profile_id = auth.uid()
  and public.is_field_worker()
);

drop policy if exists "location_events_staff_manage_org" on public.location_events;
create policy "location_events_staff_manage_org"
on public.location_events
for all
to authenticated
using (
  organization_id = public.current_user_organization_id()
  and (
    public.is_admin()
    or public.is_dispatcher_or_operator()
  )
)
with check (
  organization_id = public.current_user_organization_id()
  and (
    public.is_admin()
    or public.is_dispatcher_or_operator()
  )
);

drop policy if exists "location_events_worker_read_own" on public.location_events;
create policy "location_events_worker_read_own"
on public.location_events
for select
to authenticated
using (
  public.is_field_worker()
  and worker_profile_id = auth.uid()
);

drop policy if exists "location_events_worker_insert_own" on public.location_events;
create policy "location_events_worker_insert_own"
on public.location_events
for insert
to authenticated
with check (
  organization_id = public.current_user_organization_id()
  and worker_profile_id = auth.uid()
  and public.is_field_worker()
);

drop policy if exists "waitlist_leads_public_insert" on public.waitlist_leads;
create policy "waitlist_leads_public_insert"
on public.waitlist_leads
for insert
to anon, authenticated
with check (true);

drop policy if exists "waitlist_leads_admin_read" on public.waitlist_leads;
create policy "waitlist_leads_admin_read"
on public.waitlist_leads
for select
to authenticated
using (public.is_admin());
