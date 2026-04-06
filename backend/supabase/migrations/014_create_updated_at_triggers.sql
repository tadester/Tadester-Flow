create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = timezone('utc', now());
  return new;
end;
$$;

drop trigger if exists organizations_set_updated_at on public.organizations;
create trigger organizations_set_updated_at
before update on public.organizations
for each row
execute function public.set_updated_at();

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
before update on public.profiles
for each row
execute function public.set_updated_at();

drop trigger if exists locations_set_updated_at on public.locations;
create trigger locations_set_updated_at
before update on public.locations
for each row
execute function public.set_updated_at();

drop trigger if exists jobs_set_updated_at on public.jobs;
create trigger jobs_set_updated_at
before update on public.jobs
for each row
execute function public.set_updated_at();

drop trigger if exists job_assignments_set_updated_at on public.job_assignments;
create trigger job_assignments_set_updated_at
before update on public.job_assignments
for each row
execute function public.set_updated_at();
