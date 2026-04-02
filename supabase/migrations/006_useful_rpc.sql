create or replace function public.get_nearby_jobs(
  p_lng double precision,
  p_lat double precision,
  p_radius_m integer default 5000
)
returns table (
  job_id uuid,
  service_type text,
  status text,
  meters_away double precision
)
language sql
as $$
  select
    j.id as job_id,
    j.service_type,
    j.status,
    ST_Distance(
      sl.point,
      ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography
    ) as meters_away
  from public.jobs j
  join public.service_locations sl on sl.id = j.service_location_id
  where ST_DWithin(
    sl.point,
    ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography,
    p_radius_m
  )
  order by meters_away asc;
$$;