do $$
declare
  org_id uuid := '10000000-0000-0000-0000-000000000001';
  admin_id uuid := '10000000-0000-0000-0000-000000000101';
  dispatcher_id uuid := '10000000-0000-0000-0000-000000000102';
  operator_id uuid := '10000000-0000-0000-0000-000000000103';
  worker_one_id uuid := '10000000-0000-0000-0000-000000000104';
  worker_two_id uuid := '10000000-0000-0000-0000-000000000105';
  location_one_id uuid := '10000000-0000-0000-0000-000000000201';
  location_two_id uuid := '10000000-0000-0000-0000-000000000202';
  location_three_id uuid := '10000000-0000-0000-0000-000000000203';
  job_one_id uuid := '10000000-0000-0000-0000-000000000301';
  job_two_id uuid := '10000000-0000-0000-0000-000000000302';
  job_three_id uuid := '10000000-0000-0000-0000-000000000303';
  job_four_id uuid := '10000000-0000-0000-0000-000000000304';
  job_five_id uuid := '10000000-0000-0000-0000-000000000305';
begin
  delete from public.location_events
  where worker_profile_id in (worker_one_id, worker_two_id)
    and (
      job_id in (job_two_id, job_three_id)
      or location_id in (location_two_id, location_three_id)
    );

  delete from public.worker_location_pings
  where worker_profile_id in (worker_one_id, worker_two_id);

  delete from public.waitlist_leads
  where lower(email) in (
    'jamie@example.com',
    'avery@example.com',
    'casey@example.com'
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
      admin_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'admin@tadesterops.dev',
      crypt('password123', gen_salt('bf')),
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{"seeded":true}',
      timezone('utc', now()),
      timezone('utc', now())
    ),
    (
      dispatcher_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'dispatcher@tadesterops.dev',
      crypt('password123', gen_salt('bf')),
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{"seeded":true}',
      timezone('utc', now()),
      timezone('utc', now())
    ),
    (
      operator_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'operator@tadesterops.dev',
      crypt('password123', gen_salt('bf')),
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{"seeded":true}',
      timezone('utc', now()),
      timezone('utc', now())
    ),
    (
      worker_one_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'worker.one@tadesterops.dev',
      crypt('password123', gen_salt('bf')),
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{"seeded":true}',
      timezone('utc', now()),
      timezone('utc', now())
    ),
    (
      worker_two_id,
      '00000000-0000-0000-0000-000000000000',
      'authenticated',
      'authenticated',
      'worker.two@tadesterops.dev',
      crypt('password123', gen_salt('bf')),
      timezone('utc', now()),
      '{"provider":"email","providers":["email"]}',
      '{"seeded":true}',
      timezone('utc', now()),
      timezone('utc', now())
    )
  on conflict (id) do nothing;

  insert into public.organizations (id, name, slug, status)
  values (org_id, 'Tadester Ops Demo Org', 'tadester-ops-demo', 'active')
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
    (admin_id, org_id, 'admin@tadesterops.dev', 'Morgan Admin', 'admin', 'active', '555-0101'),
    (dispatcher_id, org_id, 'dispatcher@tadesterops.dev', 'Drew Dispatcher', 'dispatcher', 'active', '555-0102'),
    (operator_id, org_id, 'operator@tadesterops.dev', 'Owen Operator', 'operator', 'active', '555-0103'),
    (worker_one_id, org_id, 'worker.one@tadesterops.dev', 'Finley Worker', 'field_worker', 'active', '555-0104'),
    (worker_two_id, org_id, 'worker.two@tadesterops.dev', 'Riley Worker', 'field_worker', 'active', '555-0105')
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
    (
      location_one_id,
      org_id,
      'North Industrial Site',
      '10101 121 St NW',
      'Edmonton',
      'AB',
      'T5G 0B1',
      'Canada',
      53.555300,
      -113.496300,
      120,
      'active',
      dispatcher_id
    ),
    (
      location_two_id,
      org_id,
      'Riverbend Commercial Lot',
      '5230 Riverbend Rd NW',
      'Edmonton',
      'AB',
      'T6H 5K7',
      'Canada',
      53.498100,
      -113.530400,
      100,
      'active',
      dispatcher_id
    ),
    (
      location_three_id,
      org_id,
      'South Yard Depot',
      '8803 51 Ave NW',
      'Edmonton',
      'AB',
      'T6E 5J3',
      'Canada',
      53.487200,
      -113.471000,
      90,
      'active',
      operator_id
    )
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
    (
      job_one_id,
      org_id,
      location_one_id,
      'Snow clearing - north lot',
      'Scheduled morning clearing pass.',
      'scheduled',
      'medium',
      timezone('utc', now()) + interval '4 hours',
      timezone('utc', now()) + interval '6 hours',
      dispatcher_id
    ),
    (
      job_two_id,
      org_id,
      location_two_id,
      'Salting - riverbend walkways',
      'Urgent salting after overnight freeze.',
      'in_progress',
      'urgent',
      timezone('utc', now()) - interval '1 hour',
      timezone('utc', now()) + interval '2 hours',
      dispatcher_id
    ),
    (
      job_three_id,
      org_id,
      location_three_id,
      'Equipment pickup',
      'Move skid steer back to yard.',
      'completed',
      'low',
      timezone('utc', now()) - interval '8 hours',
      timezone('utc', now()) - interval '6 hours',
      operator_id
    ),
    (
      job_four_id,
      org_id,
      location_one_id,
      'Fence line inspection',
      'Field check before next dispatch cycle.',
      'scheduled',
      'high',
      timezone('utc', now()) + interval '8 hours',
      timezone('utc', now()) + interval '10 hours',
      dispatcher_id
    ),
    (
      job_five_id,
      org_id,
      location_two_id,
      'Evening de-icing pass',
      'Second pass for heavy pedestrian areas.',
      'draft',
      'high',
      timezone('utc', now()) + interval '12 hours',
      timezone('utc', now()) + interval '14 hours',
      dispatcher_id
    )
  on conflict (id) do nothing;

  insert into public.job_assignments (
    organization_id,
    job_id,
    worker_profile_id,
    assignment_status,
    assigned_at,
    assigned_by
  )
  values
    (org_id, job_one_id, worker_one_id, 'assigned', timezone('utc', now()) - interval '30 minutes', dispatcher_id),
    (org_id, job_two_id, worker_two_id, 'accepted', timezone('utc', now()) - interval '90 minutes', dispatcher_id),
    (org_id, job_three_id, worker_one_id, 'completed', timezone('utc', now()) - interval '10 hours', operator_id),
    (org_id, job_four_id, worker_two_id, 'assigned', timezone('utc', now()) - interval '25 minutes', dispatcher_id)
  on conflict (job_id, worker_profile_id) do nothing;

  insert into public.worker_location_pings (
    organization_id,
    worker_profile_id,
    latitude,
    longitude,
    accuracy_meters,
    recorded_at,
    source
  )
  values
    (org_id, worker_one_id, 53.555150, -113.496120, 8.5, timezone('utc', now()) - interval '12 minutes', 'mobile_foreground'),
    (org_id, worker_one_id, 53.555260, -113.496240, 7.2, timezone('utc', now()) - interval '5 minutes', 'mobile_background'),
    (org_id, worker_two_id, 53.498240, -113.530580, 6.8, timezone('utc', now()) - interval '15 minutes', 'mobile_foreground'),
    (org_id, worker_two_id, 53.498390, -113.530700, 5.1, timezone('utc', now()) - interval '4 minutes', 'mobile_background');

  insert into public.location_events (
    organization_id,
    job_id,
    location_id,
    worker_profile_id,
    event_type,
    event_timestamp,
    metadata
  )
  values
    (
      org_id,
      job_two_id,
      location_two_id,
      worker_two_id,
      'geofence_enter',
      timezone('utc', now()) - interval '50 minutes',
      '{"source":"mobile_background"}'::jsonb
    ),
    (
      org_id,
      job_two_id,
      location_two_id,
      worker_two_id,
      'job_started',
      timezone('utc', now()) - interval '45 minutes',
      '{"started_by":"worker"}'::jsonb
    ),
    (
      org_id,
      job_three_id,
      location_three_id,
      worker_one_id,
      'arrival',
      timezone('utc', now()) - interval '7 hours',
      '{"source":"mobile_foreground"}'::jsonb
    ),
    (
      org_id,
      job_three_id,
      location_three_id,
      worker_one_id,
      'job_completed',
      timezone('utc', now()) - interval '6 hours 20 minutes',
      '{"completed_via":"mobile"}'::jsonb
    ),
    (
      org_id,
      job_three_id,
      location_three_id,
      worker_one_id,
      'geofence_exit',
      timezone('utc', now()) - interval '6 hours',
      '{"source":"mobile_background"}'::jsonb
    );

  insert into public.waitlist_leads (
    name,
    email,
    company,
    phone,
    message
  )
  values
    ('Jamie Prospect', 'jamie@example.com', 'Northline Services', '555-2101', 'Interested in dispatch workflows.'),
    ('Avery Prospect', 'avery@example.com', 'Prairie Snow', '555-2102', 'Need live worker visibility.'),
    ('Casey Prospect', 'casey@example.com', 'Atlas Grounds', null, 'Looking for routing and geofencing.')
  on conflict do nothing;
end $$;
