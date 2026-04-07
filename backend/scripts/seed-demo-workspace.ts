import path from "path";

import dotenv from "dotenv";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

dotenv.config({ path: path.resolve(__dirname, "..", ".env") });

type AppRole = "admin" | "dispatcher" | "operator" | "field_worker";

type OrganizationSeed = {
  id: string;
  name: string;
  slug: string;
};

type UserSeed = {
  email: string;
  fullName: string;
  phone: string;
  role: AppRole;
  organizationId: string;
};

type LocationSeed = {
  id: string;
  organizationId: string;
  name: string;
  addressLine1: string;
  city: string;
  region: string;
  postalCode: string;
  country: string;
  latitude: number;
  longitude: number;
  geofenceRadiusMeters: number;
  createdByEmail: string;
};

type JobSeed = {
  id: string;
  organizationId: string;
  locationId: string;
  title: string;
  description: string;
  status: "scheduled" | "in_progress";
  priority: "low" | "medium" | "high" | "urgent";
  startsInHours: number;
  durationHours: number;
  createdByEmail: string;
};

type AssignmentSeed = {
  id: string;
  organizationId: string;
  jobId: string;
  workerEmail: string;
  assignmentStatus: "assigned" | "accepted";
  assignedByEmail: string;
};

type PingSeed = {
  id: string;
  organizationId: string;
  workerEmail: string;
  latitude: number;
  longitude: number;
  accuracyMeters: number;
  minutesAgo: number;
  source: string;
};

type EventSeed = {
  id: string;
  organizationId: string;
  jobId: string;
  locationId: string;
  workerEmail: string;
  eventType: string;
  minutesAgo: number;
};

type DemoUserRecord = {
  id: string;
  email: string;
  fullName: string;
  role: AppRole;
  organizationId: string;
  phone: string;
};

const organizations: OrganizationSeed[] = [
  {
    id: "20000000-0000-0000-0000-000000000001",
    name: "Northwind Snow Services",
    slug: "northwind-snow-services",
  },
  {
    id: "30000000-0000-0000-0000-000000000001",
    name: "Prairie Site Ops",
    slug: "prairie-site-ops",
  },
];

const users: UserSeed[] = [
  {
    email: "demo.north.admin@tadesterops.dev",
    fullName: "Noah North",
    phone: "555-0201",
    role: "admin",
    organizationId: organizations[0].id,
  },
  {
    email: "demo.north.dispatcher@tadesterops.dev",
    fullName: "Dana Dispatch",
    phone: "555-0202",
    role: "dispatcher",
    organizationId: organizations[0].id,
  },
  {
    email: "demo.north.worker.one@tadesterops.dev",
    fullName: "Harper Haul",
    phone: "555-0203",
    role: "field_worker",
    organizationId: organizations[0].id,
  },
  {
    email: "demo.north.worker.two@tadesterops.dev",
    fullName: "Parker Plow",
    phone: "555-0204",
    role: "field_worker",
    organizationId: organizations[0].id,
  },
  {
    email: "demo.prairie.admin@tadesterops.dev",
    fullName: "Avery Prairie",
    phone: "555-0301",
    role: "admin",
    organizationId: organizations[1].id,
  },
  {
    email: "demo.prairie.operator@tadesterops.dev",
    fullName: "Olive Operator",
    phone: "555-0302",
    role: "operator",
    organizationId: organizations[1].id,
  },
  {
    email: "demo.prairie.worker.one@tadesterops.dev",
    fullName: "Jordan Junction",
    phone: "555-0303",
    role: "field_worker",
    organizationId: organizations[1].id,
  },
  {
    email: "demo.prairie.worker.two@tadesterops.dev",
    fullName: "Logan Linehaul",
    phone: "555-0304",
    role: "field_worker",
    organizationId: organizations[1].id,
  },
];

const locations: LocationSeed[] = [
  {
    id: "20000000-0000-0000-0000-000000000201",
    organizationId: organizations[0].id,
    name: "Northwind Yard",
    addressLine1: "11808 170 St NW",
    city: "Edmonton",
    region: "AB",
    postalCode: "T5S 1L7",
    country: "Canada",
    latitude: 53.5763,
    longitude: -113.6144,
    geofenceRadiusMeters: 125,
    createdByEmail: "demo.north.admin@tadesterops.dev",
  },
  {
    id: "20000000-0000-0000-0000-000000000202",
    organizationId: organizations[0].id,
    name: "Castle Downs Complex",
    addressLine1: "11440 153 Ave NW",
    city: "Edmonton",
    region: "AB",
    postalCode: "T5X 6C7",
    country: "Canada",
    latitude: 53.6145,
    longitude: -113.5281,
    geofenceRadiusMeters: 110,
    createdByEmail: "demo.north.dispatcher@tadesterops.dev",
  },
  {
    id: "30000000-0000-0000-0000-000000000201",
    organizationId: organizations[1].id,
    name: "Sherwood Logistics Hub",
    addressLine1: "260 Sioux Rd",
    city: "Sherwood Park",
    region: "AB",
    postalCode: "T8A 4X1",
    country: "Canada",
    latitude: 53.5409,
    longitude: -113.2469,
    geofenceRadiusMeters: 135,
    createdByEmail: "demo.prairie.admin@tadesterops.dev",
  },
  {
    id: "30000000-0000-0000-0000-000000000202",
    organizationId: organizations[1].id,
    name: "Leduc South Depot",
    addressLine1: "4705 65 Ave",
    city: "Leduc",
    region: "AB",
    postalCode: "T9E 7A1",
    country: "Canada",
    latitude: 53.2742,
    longitude: -113.5617,
    geofenceRadiusMeters: 140,
    createdByEmail: "demo.prairie.operator@tadesterops.dev",
  },
];

const jobs: JobSeed[] = [
  {
    id: "20000000-0000-0000-0000-000000000301",
    organizationId: organizations[0].id,
    locationId: "20000000-0000-0000-0000-000000000201",
    title: "Loader maintenance inspection",
    description: "Inspect and sign off morning equipment checks.",
    status: "scheduled",
    priority: "medium",
    startsInHours: 2,
    durationHours: 2,
    createdByEmail: "demo.north.dispatcher@tadesterops.dev",
  },
  {
    id: "20000000-0000-0000-0000-000000000302",
    organizationId: organizations[0].id,
    locationId: "20000000-0000-0000-0000-000000000202",
    title: "Parking lot salting",
    description: "Priority de-icing after overnight freeze.",
    status: "in_progress",
    priority: "urgent",
    startsInHours: -1,
    durationHours: 2,
    createdByEmail: "demo.north.dispatcher@tadesterops.dev",
  },
  {
    id: "20000000-0000-0000-0000-000000000303",
    organizationId: organizations[0].id,
    locationId: "20000000-0000-0000-0000-000000000201",
    title: "Evening yard sweep",
    description: "Sweep and secure snow routes for morning dispatch.",
    status: "scheduled",
    priority: "low",
    startsInHours: 8,
    durationHours: 2,
    createdByEmail: "demo.north.admin@tadesterops.dev",
  },
  {
    id: "30000000-0000-0000-0000-000000000301",
    organizationId: organizations[1].id,
    locationId: "30000000-0000-0000-0000-000000000201",
    title: "Material drop inspection",
    description: "Verify delivery zone clearance and staging.",
    status: "scheduled",
    priority: "high",
    startsInHours: 3,
    durationHours: 2,
    createdByEmail: "demo.prairie.operator@tadesterops.dev",
  },
  {
    id: "30000000-0000-0000-0000-000000000302",
    organizationId: organizations[1].id,
    locationId: "30000000-0000-0000-0000-000000000202",
    title: "Fuel run and inventory scan",
    description: "Inventory confirmation before outbound dispatch.",
    status: "in_progress",
    priority: "medium",
    startsInHours: -1,
    durationHours: 2,
    createdByEmail: "demo.prairie.operator@tadesterops.dev",
  },
  {
    id: "30000000-0000-0000-0000-000000000303",
    organizationId: organizations[1].id,
    locationId: "30000000-0000-0000-0000-000000000202",
    title: "Depot shutdown checklist",
    description: "Close-out and geofence verification before end of day.",
    status: "scheduled",
    priority: "medium",
    startsInHours: 7,
    durationHours: 2,
    createdByEmail: "demo.prairie.admin@tadesterops.dev",
  },
];

const assignments: AssignmentSeed[] = [
  {
    id: "20000000-0000-0000-0000-000000000401",
    organizationId: organizations[0].id,
    jobId: "20000000-0000-0000-0000-000000000301",
    workerEmail: "demo.north.worker.one@tadesterops.dev",
    assignmentStatus: "assigned",
    assignedByEmail: "demo.north.dispatcher@tadesterops.dev",
  },
  {
    id: "20000000-0000-0000-0000-000000000402",
    organizationId: organizations[0].id,
    jobId: "20000000-0000-0000-0000-000000000302",
    workerEmail: "demo.north.worker.two@tadesterops.dev",
    assignmentStatus: "accepted",
    assignedByEmail: "demo.north.dispatcher@tadesterops.dev",
  },
  {
    id: "30000000-0000-0000-0000-000000000401",
    organizationId: organizations[1].id,
    jobId: "30000000-0000-0000-0000-000000000301",
    workerEmail: "demo.prairie.worker.one@tadesterops.dev",
    assignmentStatus: "assigned",
    assignedByEmail: "demo.prairie.operator@tadesterops.dev",
  },
  {
    id: "30000000-0000-0000-0000-000000000402",
    organizationId: organizations[1].id,
    jobId: "30000000-0000-0000-0000-000000000302",
    workerEmail: "demo.prairie.worker.two@tadesterops.dev",
    assignmentStatus: "accepted",
    assignedByEmail: "demo.prairie.operator@tadesterops.dev",
  },
];

const pings: PingSeed[] = [
  {
    id: "20000000-0000-0000-0000-000000000501",
    organizationId: organizations[0].id,
    workerEmail: "demo.north.worker.one@tadesterops.dev",
    latitude: 53.5766,
    longitude: -113.614,
    accuracyMeters: 9,
    minutesAgo: 4,
    source: "manual_test",
  },
  {
    id: "20000000-0000-0000-0000-000000000502",
    organizationId: organizations[0].id,
    workerEmail: "demo.north.worker.two@tadesterops.dev",
    latitude: 53.6141,
    longitude: -113.5284,
    accuracyMeters: 12,
    minutesAgo: 2,
    source: "manual_test",
  },
  {
    id: "30000000-0000-0000-0000-000000000501",
    organizationId: organizations[1].id,
    workerEmail: "demo.prairie.worker.one@tadesterops.dev",
    latitude: 53.5412,
    longitude: -113.2473,
    accuracyMeters: 8,
    minutesAgo: 5,
    source: "manual_test",
  },
  {
    id: "30000000-0000-0000-0000-000000000502",
    organizationId: organizations[1].id,
    workerEmail: "demo.prairie.worker.two@tadesterops.dev",
    latitude: 53.2746,
    longitude: -113.5611,
    accuracyMeters: 10,
    minutesAgo: 3,
    source: "manual_test",
  },
];

const events: EventSeed[] = [
  {
    id: "20000000-0000-0000-0000-000000000601",
    organizationId: organizations[0].id,
    jobId: "20000000-0000-0000-0000-000000000302",
    locationId: "20000000-0000-0000-0000-000000000202",
    workerEmail: "demo.north.worker.two@tadesterops.dev",
    eventType: "geofence_enter",
    minutesAgo: 20,
  },
  {
    id: "20000000-0000-0000-0000-000000000602",
    organizationId: organizations[0].id,
    jobId: "20000000-0000-0000-0000-000000000302",
    locationId: "20000000-0000-0000-0000-000000000202",
    workerEmail: "demo.north.worker.two@tadesterops.dev",
    eventType: "arrival",
    minutesAgo: 15,
  },
  {
    id: "30000000-0000-0000-0000-000000000601",
    organizationId: organizations[1].id,
    jobId: "30000000-0000-0000-0000-000000000302",
    locationId: "30000000-0000-0000-0000-000000000202",
    workerEmail: "demo.prairie.worker.two@tadesterops.dev",
    eventType: "geofence_enter",
    minutesAgo: 18,
  },
  {
    id: "30000000-0000-0000-0000-000000000602",
    organizationId: organizations[1].id,
    jobId: "30000000-0000-0000-0000-000000000302",
    locationId: "30000000-0000-0000-0000-000000000202",
    workerEmail: "demo.prairie.worker.two@tadesterops.dev",
    eventType: "job_started",
    minutesAgo: 12,
  },
];

const demoEmails = users.map((user) => user.email);
const demoOrganizationIds = organizations.map((organization) => organization.id);

async function main() {
  const supabase = createAdminClient();
  const password = process.env.DEMO_SEED_PASSWORD ?? "password123";

  console.log("Seeding demo workspace data...");

  await cleanupExistingDemoData(supabase);
  await upsertOrganizations(supabase);

  const createdUsers = await createOrResetDemoUsers(supabase, password);
  await upsertProfiles(supabase, createdUsers);
  await upsertLocations(supabase, createdUsers);
  await upsertJobs(supabase, createdUsers);
  await upsertAssignments(supabase, createdUsers);
  await upsertPings(supabase, createdUsers);
  await upsertEvents(supabase, createdUsers);

  console.log("Demo workspace seed complete. Working accounts:");
  for (const user of createdUsers) {
    console.log(`- ${user.email} / ${password} (${user.role})`);
  }
}

function createAdminClient() {
  const supabaseUrl = requireEnv("SUPABASE_URL");
  const serviceRoleKey = requireEnv("SUPABASE_SERVICE_ROLE_KEY");

  return createClient(supabaseUrl, serviceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

function requireEnv(name: string): string {
  const value = process.env[name];
  if (!value) {
    throw new Error(`Missing required environment variable: ${name}`);
  }
  return value;
}

async function cleanupExistingDemoData(supabase: SupabaseClient) {
  const existingUsers = await listProfileUsersByEmail(supabase, demoEmails);

  await deleteByOrganizationIds(supabase, "location_events");
  await deleteByOrganizationIds(supabase, "worker_location_pings");
  await deleteByOrganizationIds(supabase, "job_assignments");
  await deleteByOrganizationIds(supabase, "jobs");
  await deleteByOrganizationIds(supabase, "locations");
  await deleteByOrganizationIds(supabase, "profiles");

  for (const user of existingUsers) {
    const { error } = await supabase.auth.admin.deleteUser(user.id);
    if (error) {
      throw new Error(`Failed to delete demo auth user ${user.email}: ${error.message}`);
    }
  }
}

async function deleteByOrganizationIds(supabase: SupabaseClient, table: string) {
  const { error } = await supabase
    .from(table)
    .delete()
    .in("organization_id", demoOrganizationIds);

  if (error) {
    throw new Error(`Failed to clean ${table}: ${error.message}`);
  }
}

async function listProfileUsersByEmail(supabase: SupabaseClient, emails: string[]) {
  const { data, error } = await supabase
    .from("profiles")
    .select("id, email")
    .in("email", emails);

  if (error) {
    throw new Error(`Failed to list demo profiles: ${error.message}`);
  }

  return (data ?? []).filter(
    (user): user is { id: string; email: string } => Boolean(user.id && user.email),
  );
}

async function upsertOrganizations(supabase: SupabaseClient) {
  const { error } = await supabase.from("organizations").upsert(
    organizations.map((organization) => ({
      id: organization.id,
      name: organization.name,
      slug: organization.slug,
      status: "active",
    })),
    { onConflict: "id" },
  );

  if (error) {
    throw new Error(`Failed to upsert organizations: ${error.message}`);
  }
}

async function createOrResetDemoUsers(
  supabase: SupabaseClient,
  password: string,
): Promise<DemoUserRecord[]> {
  const createdUsers: DemoUserRecord[] = [];

  for (const user of users) {
    const { data, error } = await supabase.auth.admin.createUser({
      email: user.email,
      password,
      email_confirm: true,
      user_metadata: {
        full_name: user.fullName,
        phone: user.phone,
        role: user.role,
        organization_id: user.organizationId,
        seeded: true,
      },
    });

    if (error || !data.user) {
      throw new Error(`Failed to create demo user ${user.email}: ${error?.message ?? "unknown error"}`);
    }

    createdUsers.push({
      id: data.user.id,
      email: user.email,
      fullName: user.fullName,
      role: user.role,
      organizationId: user.organizationId,
      phone: user.phone,
    });
  }

  return createdUsers;
}

async function upsertProfiles(
  supabase: SupabaseClient,
  usersById: DemoUserRecord[],
) {
  const { error } = await supabase.from("profiles").upsert(
    usersById.map((user) => ({
      id: user.id,
      organization_id: user.organizationId,
      email: user.email,
      full_name: user.fullName,
      role: user.role,
      status: "active",
      phone: user.phone,
    })),
    { onConflict: "id" },
  );

  if (error) {
    throw new Error(`Failed to upsert profiles: ${error.message}`);
  }
}

async function upsertLocations(
  supabase: SupabaseClient,
  usersById: DemoUserRecord[],
) {
  const userMap = new Map(usersById.map((user) => [user.email, user]));

  const { error } = await supabase.from("locations").upsert(
    locations.map((location) => ({
      id: location.id,
      organization_id: location.organizationId,
      name: location.name,
      address_line_1: location.addressLine1,
      city: location.city,
      region: location.region,
      postal_code: location.postalCode,
      country: location.country,
      latitude: location.latitude,
      longitude: location.longitude,
      geofence_radius_meters: location.geofenceRadiusMeters,
      status: "active",
      created_by: requireUser(userMap, location.createdByEmail).id,
    })),
    { onConflict: "id" },
  );

  if (error) {
    throw new Error(`Failed to upsert locations: ${error.message}`);
  }
}

async function upsertJobs(
  supabase: SupabaseClient,
  usersById: DemoUserRecord[],
) {
  const userMap = new Map(usersById.map((user) => [user.email, user]));

  const { error } = await supabase.from("jobs").upsert(
    jobs.map((job) => {
      const scheduledStartAt = isoFromNow(job.startsInHours);
      const scheduledEndAt = isoFromDate(
        new Date(Date.parse(scheduledStartAt) + job.durationHours * 60 * 60 * 1000),
      );

      return {
        id: job.id,
        organization_id: job.organizationId,
        location_id: job.locationId,
        title: job.title,
        description: job.description,
        status: job.status,
        priority: job.priority,
        scheduled_start_at: scheduledStartAt,
        scheduled_end_at: scheduledEndAt,
        created_by: requireUser(userMap, job.createdByEmail).id,
      };
    }),
    { onConflict: "id" },
  );

  if (error) {
    throw new Error(`Failed to upsert jobs: ${error.message}`);
  }
}

async function upsertAssignments(
  supabase: SupabaseClient,
  usersById: DemoUserRecord[],
) {
  const userMap = new Map(usersById.map((user) => [user.email, user]));

  const { error } = await supabase.from("job_assignments").upsert(
    assignments.map((assignment) => ({
      id: assignment.id,
      organization_id: assignment.organizationId,
      job_id: assignment.jobId,
      worker_profile_id: requireUser(userMap, assignment.workerEmail).id,
      assignment_status: assignment.assignmentStatus,
      assigned_at: new Date().toISOString(),
      assigned_by: requireUser(userMap, assignment.assignedByEmail).id,
    })),
    { onConflict: "id" },
  );

  if (error) {
    throw new Error(`Failed to upsert assignments: ${error.message}`);
  }
}

async function upsertPings(
  supabase: SupabaseClient,
  usersById: DemoUserRecord[],
) {
  const userMap = new Map(usersById.map((user) => [user.email, user]));

  const { error } = await supabase.from("worker_location_pings").upsert(
    pings.map((ping) => ({
      id: ping.id,
      organization_id: ping.organizationId,
      worker_profile_id: requireUser(userMap, ping.workerEmail).id,
      latitude: ping.latitude,
      longitude: ping.longitude,
      accuracy_meters: ping.accuracyMeters,
      recorded_at: isoMinutesAgo(ping.minutesAgo),
      source: ping.source,
    })),
    { onConflict: "id" },
  );

  if (error) {
    throw new Error(`Failed to upsert worker pings: ${error.message}`);
  }
}

async function upsertEvents(
  supabase: SupabaseClient,
  usersById: DemoUserRecord[],
) {
  const userMap = new Map(usersById.map((user) => [user.email, user]));

  const { error } = await supabase.from("location_events").upsert(
    events.map((event) => ({
      id: event.id,
      organization_id: event.organizationId,
      job_id: event.jobId,
      location_id: event.locationId,
      worker_profile_id: requireUser(userMap, event.workerEmail).id,
      event_type: event.eventType,
      event_timestamp: isoMinutesAgo(event.minutesAgo),
      metadata: { source: "demo_seed_script" },
    })),
    { onConflict: "id" },
  );

  if (error) {
    throw new Error(`Failed to upsert location events: ${error.message}`);
  }
}

function requireUser(userMap: Map<string, DemoUserRecord>, email: string) {
  const user = userMap.get(email);
  if (!user) {
    throw new Error(`Missing seeded user for ${email}`);
  }
  return user;
}

function isoFromNow(hoursFromNow: number) {
  return isoFromDate(new Date(Date.now() + hoursFromNow * 60 * 60 * 1000));
}

function isoMinutesAgo(minutesAgo: number) {
  return isoFromDate(new Date(Date.now() - minutesAgo * 60 * 1000));
}

function isoFromDate(value: Date) {
  return value.toISOString();
}

main().catch((error: unknown) => {
  const message = error instanceof Error ? error.message : String(error);
  console.error(`Demo workspace seed failed: ${message}`);
  process.exitCode = 1;
});
