-- Additional realistic Phase 9 demo data for org-aware signup and admin dashboard testing.

do $$
declare
  org_two_id uuid := '20000000-0000-0000-0000-000000000001';
  org_three_id uuid := '30000000-0000-0000-0000-000000000001';

  north_admin_id uuid := '20000000-0000-0000-0000-000000000101';
  north_dispatcher_id uuid := '20000000-0000-0000-0000-000000000102';
  north_worker_one_id uuid := '20000000-0000-0000-0000-000000000103';
  north_worker_two_id uuid := '20000000-0000-0000-0000-000000000104';

  prairie_admin_id uuid := '30000000-0000-0000-0000-000000000101';
  prairie_operator_id uuid := '30000000-0000-0000-0000-000000000102';
  prairie_worker_one_id uuid := '30000000-0000-0000-0000-000000000103';
  prairie_worker_two_id uuid := '30000000-0000-0000-0000-000000000104';

  north_location_one_id uuid := '20000000-0000-0000-0000-000000000201';
  north_location_two_id uuid := '20000000-0000-0000-0000-000000000202';
  prairie_location_one_id uuid := '30000000-0000-0000-0000-000000000201';
  prairie_location_two_id uuid := '30000000-0000-0000-0000-000000000202';

  north_job_one_id uuid := '20000000-0000-0000-0000-000000000301';
  north_job_two_id uuid := '20000000-0000-0000-0000-000000000302';
  north_job_three_id uuid := '20000000-0000-0000-0000-000000000303';
  prairie_job_one_id uuid := '30000000-0000-0000-0000-000000000301';
  prairie_job_two_id uuid := '30000000-0000-0000-0000-000000000302';
  prairie_job_three_id uuid := '30000000-0000-0000-0000-000000000303';
begin
  delete from public.location_events
  where worker_profile_id in (
    north_worker_one_id,
    north_worker_two_id,
    prairie_worker_one_id,
    prairie_worker_two_id
  );

  delete from public.worker_location_pings
  where worker_profile_id in (
    north_worker_one_id,
    north_worker_two_id,
    prairie_worker_one_id,
    prairie_worker_two_id
  );

  insert into auth.users (
    id,
    instance_id,
    aud,
    role,
    email,
    encrypted_password,
    email_confirmed_at,
    raw_app_meta_data,
    raw_user_meta_data,
    created_at,
    updated_at
  )
  values
    (
      north_admin_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'north.admin@tadesterops.dev',
      crypt('password123', gen_salt('bf')),
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{"seeded":true}',
      timezone('utc', now()),
      timezone('utc', now())
    ),
    (
      north_dispatcher_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'north.dispatcher@tadesterops.dev',
      crypt('password123', gen_salt('bf')),
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{"seeded":true}',
      timezone('utc', now()),
      timezone('utc', now())
    ),
    (
      north_worker_one_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'north.worker.one@tadesterops.dev',
      crypt('password123', gen_salt('bf')),
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{"seeded":true}',
      timezone('utc', now()),
      timezone('utc', now())
    ),
    (
      north_worker_two_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'north.worker.two@tadesterops.dev',
      crypt('password123', gen_salt('bf')),
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{"seeded":true}',
      timezone('utc', now()),
      timezone('utc', now())
    ),
    (
      prairie_admin_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'prairie.admin@tadesterops.dev',
      crypt('password123', gen_salt('bf')),
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{"seeded":true}',
      timezone('utc', now()),
      timezone('utc', now())
    ),
    (
      prairie_operator_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'prairie.operator@tadesterops.dev',
      crypt('password123', gen_salt('bf')),
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{"seeded":true}',
      timezone('utc', now()),
      timezone('utc', now())
    ),
    (
      prairie_worker_one_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'prairie.worker.one@tadesterops.dev',
      crypt('password123', gen_salt('bf')),
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{"seeded":true}',
      timezone('utc', now()),
      timezone('utc', now())
    ),
    (
      prairie_worker_two_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'prairie.worker.two@tadesterops.dev',
      crypt('password123', gen_salt('bf')),
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{"seeded":true}',
      timezone('utc', now()),
      timezone('utc', now())
    )
  on conflict (id) do nothing;

  insert into public.organizations (id, name, slug, status)
  values
    (org_two_id, 'Northwind Snow Services', 'northwind-snow-services', 'active'),
    (org_three_id, 'Prairie Site Ops', 'prairie-site-ops', 'active')
  on conflict (id) do nothing;

  insert into public.profiles (
    id,
    organization_id,
    email,
    full_name,
    role,
    status,
    phone
  )
  values
    (north_admin_id, org_two_id, 'north.admin@tadesterops.dev', 'Noah North', 'admin', 'active', '555-0201'),
    (north_dispatcher_id, org_two_id, 'north.dispatcher@tadesterops.dev', 'Dana Dispatch', 'dispatcher', 'active', '555-0202'),
    (north_worker_one_id, org_two_id, 'north.worker.one@tadesterops.dev', 'Harper Haul', 'field_worker', 'active', '555-0203'),
    (north_worker_two_id, org_two_id, 'north.worker.two@tadesterops.dev', 'Parker Plow', 'field_worker', 'active', '555-0204'),
    (prairie_admin_id, org_three_id, 'prairie.admin@tadesterops.dev', 'Avery Prairie', 'admin', 'active', '555-0301'),
    (prairie_operator_id, org_three_id, 'prairie.operator@tadesterops.dev', 'Olive Operator', 'operator', 'active', '555-0302'),
    (prairie_worker_one_id, org_three_id, 'prairie.worker.one@tadesterops.dev', 'Jordan Junction', 'field_worker', 'active', '555-0303'),
    (prairie_worker_two_id, org_three_id, 'prairie.worker.two@tadesterops.dev', 'Logan Linehaul', 'field_worker', 'active', '555-0304')
  on conflict (id) do nothing;

  insert into public.locations (
    id,
    organization_id,
    name,
    address_line_1,
    city,
    region,
    postal_code,
    country,
    latitude,
    longitude,
    geofence_radius_meters,
    status,
    created_by
  )
  values
    (north_location_one_id, org_two_id, 'Northwind Yard', '11808 170 St NW', 'Edmonton', 'AB', 'T5S 1L7', 'Canada', 53.5763, -113.6144, 125, 'active', north_admin_id),
    (north_location_two_id, org_two_id, 'Castle Downs Complex', '11440 153 Ave NW', 'Edmonton', 'AB', 'T5X 6C7', 'Canada', 53.6145, -113.5281, 110, 'active', north_dispatcher_id),
    (prairie_location_one_id, org_three_id, 'Sherwood Logistics Hub', '260 Sioux Rd', 'Sherwood Park', 'AB', 'T8A 4X1', 'Canada', 53.5409, -113.2469, 135, 'active', prairie_admin_id),
    (prairie_location_two_id, org_three_id, 'Leduc South Depot', '4705 65 Ave', 'Leduc', 'AB', 'T9E 7A1', 'Canada', 53.2742, -113.5617, 140, 'active', prairie_operator_id)
  on conflict (id) do nothing;

  insert into public.jobs (
    id,
    organization_id,
    location_id,
    title,
    description,
    status,
    priority,
    scheduled_start_at,
    scheduled_end_at,
    created_by
  )
  values
    (north_job_one_id, org_two_id, north_location_one_id, 'Loader maintenance inspection', 'Inspect and sign off morning equipment checks.', 'scheduled', 'medium', timezone('utc', now()) + interval '2 hours', timezone('utc', now()) + interval '4 hours', north_dispatcher_id),
    (north_job_two_id, org_two_id, north_location_two_id, 'Parking lot salting', 'Priority de-icing after overnight freeze.', 'in_progress', 'urgent', timezone('utc', now()) - interval '30 minutes', timezone('utc', now()) + interval '90 minutes', north_dispatcher_id),
    (north_job_three_id, org_two_id, north_location_one_id, 'Evening yard sweep', 'Sweep and secure snow routes for morning dispatch.', 'scheduled', 'low', timezone('utc', now()) + interval '8 hours', timezone('utc', now()) + interval '10 hours', north_admin_id),
    (prairie_job_one_id, org_three_id, prairie_location_one_id, 'Material drop inspection', 'Verify delivery zone clearance and staging.', 'scheduled', 'high', timezone('utc', now()) + interval '3 hours', timezone('utc', now()) + interval '5 hours', prairie_operator_id),
    (prairie_job_two_id, org_three_id, prairie_location_two_id, 'Fuel run and inventory scan', 'Inventory confirmation before outbound dispatch.', 'in_progress', 'medium', timezone('utc', now()) - interval '45 minutes', timezone('utc', now()) + interval '75 minutes', prairie_operator_id),
    (prairie_job_three_id, org_three_id, prairie_location_two_id, 'Depot shutdown checklist', 'Close-out and geofence verification before end of day.', 'scheduled', 'medium', timezone('utc', now()) + interval '7 hours', timezone('utc', now()) + interval '9 hours', prairie_admin_id)
  on conflict (id) do nothing;

  insert into public.job_assignments (
    id,
    organization_id,
    job_id,
    worker_profile_id,
    assignment_status,
    assigned_at,
    assigned_by
  )
  values
    ('20000000-0000-0000-0000-000000000401', org_two_id, north_job_one_id, north_worker_one_id, 'assigned', timezone('utc', now()), north_dispatcher_id),
    ('20000000-0000-0000-0000-000000000402', org_two_id, north_job_two_id, north_worker_two_id, 'accepted', timezone('utc', now()), north_dispatcher_id),
    ('30000000-0000-0000-0000-000000000401', org_three_id, prairie_job_one_id, prairie_worker_one_id, 'assigned', timezone('utc', now()), prairie_operator_id),
    ('30000000-0000-0000-0000-000000000402', org_three_id, prairie_job_two_id, prairie_worker_two_id, 'accepted', timezone('utc', now()), prairie_operator_id)
  on conflict (id) do nothing;

  insert into public.worker_location_pings (
    id,
    organization_id,
    worker_profile_id,
    latitude,
    longitude,
    accuracy_meters,
    recorded_at,
    source
  )
  values
    ('20000000-0000-0000-0000-000000000501', org_two_id, north_worker_one_id, 53.5766, -113.6140, 9, timezone('utc', now()) - interval '4 minutes', 'manual_test'),
    ('20000000-0000-0000-0000-000000000502', org_two_id, north_worker_two_id, 53.6141, -113.5284, 12, timezone('utc', now()) - interval '2 minutes', 'manual_test'),
    ('30000000-0000-0000-0000-000000000501', org_three_id, prairie_worker_one_id, 53.5412, -113.2473, 8, timezone('utc', now()) - interval '5 minutes', 'manual_test'),
    ('30000000-0000-0000-0000-000000000502', org_three_id, prairie_worker_two_id, 53.2746, -113.5611, 10, timezone('utc', now()) - interval '3 minutes', 'manual_test')
  on conflict (id) do nothing;

  insert into public.location_events (
    id,
    organization_id,
    job_id,
    location_id,
    worker_profile_id,
    event_type,
    event_timestamp,
    metadata
  )
  values
    ('20000000-0000-0000-0000-000000000601', org_two_id, north_job_two_id, north_location_two_id, north_worker_two_id, 'geofence_enter', timezone('utc', now()) - interval '20 minutes', '{"source":"manual_test"}'::jsonb),
    ('20000000-0000-0000-0000-000000000602', org_two_id, north_job_two_id, north_location_two_id, north_worker_two_id, 'arrival', timezone('utc', now()) - interval '15 minutes', '{"source":"manual_test"}'::jsonb),
    ('30000000-0000-0000-0000-000000000601', org_three_id, prairie_job_two_id, prairie_location_two_id, prairie_worker_two_id, 'geofence_enter', timezone('utc', now()) - interval '18 minutes', '{"source":"manual_test"}'::jsonb),
    ('30000000-0000-0000-0000-000000000602', org_three_id, prairie_job_two_id, prairie_location_two_id, prairie_worker_two_id, 'job_started', timezone('utc', now()) - interval '12 minutes', '{"source":"manual_test"}'::jsonb)
  on conflict (id) do nothing;
end $$;
