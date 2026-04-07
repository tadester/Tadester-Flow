import { handleSupabaseError } from "../utils/supabaseErrors";
import { getProfileById } from "./profileService";
import { supabaseAdmin } from "./supabaseService";

type OrganizationRecord = {
  id: string;
  name: string;
  slug: string;
  status: string;
  created_at: string;
  updated_at: string;
};

export type OrganizationWorkspace = {
  organization: OrganizationRecord;
  profile: {
    id: string;
    email: string;
    full_name: string | null;
    phone: string | null;
    role: string;
    status: string;
  };
  metrics: {
    employees_count: number;
    field_workers_count: number;
    locations_count: number;
    jobs_count: number;
    active_jobs_count: number;
  };
};

export async function getOrganizationWorkspace(input: {
  organizationId: string;
  profileId: string;
}): Promise<OrganizationWorkspace> {
  const profile = await getProfileById(input.profileId);

  const { data: organization, error: organizationError } = await supabaseAdmin
    .from("organizations")
    .select("id, name, slug, status, created_at, updated_at")
    .eq("id", input.organizationId)
    .single<OrganizationRecord>();

  if (organizationError) {
    handleSupabaseError(organizationError, "Failed to fetch organization.");
  }

  const [
    employeesCount,
    fieldWorkersCount,
    locationsCount,
    jobsCount,
    activeJobsCount,
  ] = await Promise.all([
    countOrganizationProfiles(input.organizationId),
    countOrganizationFieldWorkers(input.organizationId),
    countOrganizationLocations(input.organizationId),
    countOrganizationJobs(input.organizationId),
    countOrganizationActiveJobs(input.organizationId),
  ]);

  return {
    organization: organization as OrganizationRecord,
    profile: {
      id: profile.id,
      email: profile.email,
      full_name: profile.full_name,
      phone: profile.phone,
      role: profile.role,
      status: profile.status,
    },
    metrics: {
      employees_count: employeesCount,
      field_workers_count: fieldWorkersCount,
      locations_count: locationsCount,
      jobs_count: jobsCount,
      active_jobs_count: activeJobsCount,
    },
  };
}

async function countOrganizationProfiles(
  organizationId: string,
): Promise<number> {
  const { count, error } = await supabaseAdmin
    .from("profiles")
    .select("id", { count: "exact", head: true })
    .eq("organization_id", organizationId);

  if (error) {
    handleSupabaseError(error, "Failed to count profiles.");
  }

  return count ?? 0;
}

async function countOrganizationFieldWorkers(
  organizationId: string,
): Promise<number> {
  const { count, error } = await supabaseAdmin
    .from("profiles")
    .select("id", { count: "exact", head: true })
    .eq("organization_id", organizationId)
    .eq("role", "field_worker");

  if (error) {
    handleSupabaseError(error, "Failed to count field workers.");
  }

  return count ?? 0;
}

async function countOrganizationLocations(
  organizationId: string,
): Promise<number> {
  const { count, error } = await supabaseAdmin
    .from("locations")
    .select("id", { count: "exact", head: true })
    .eq("organization_id", organizationId);

  if (error) {
    handleSupabaseError(error, "Failed to count locations.");
  }

  return count ?? 0;
}

async function countOrganizationJobs(organizationId: string): Promise<number> {
  const { count, error } = await supabaseAdmin
    .from("jobs")
    .select("id", { count: "exact", head: true })
    .eq("organization_id", organizationId);

  if (error) {
    handleSupabaseError(error, "Failed to count jobs.");
  }

  return count ?? 0;
}

async function countOrganizationActiveJobs(
  organizationId: string,
): Promise<number> {
  const { count, error } = await supabaseAdmin
    .from("jobs")
    .select("id", { count: "exact", head: true })
    .eq("organization_id", organizationId)
    .in("status", ["scheduled", "in_progress"]);

  if (error) {
    handleSupabaseError(error, "Failed to count active jobs.");
  }

  return count ?? 0;
}
