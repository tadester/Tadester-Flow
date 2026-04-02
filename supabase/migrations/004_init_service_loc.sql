create or replace function public.set_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

create trigger trg_jobs_updated_at
before update on public.jobs
for each row execute function public.set_updated_at();

create trigger trg_routes_updated_at
before update on public.routes
for each row execute function public.set_updated_at();