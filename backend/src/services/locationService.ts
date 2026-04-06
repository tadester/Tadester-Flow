import type { AppRole } from "../domain/auth";
import type { CreateLocationInput } from "../schemas/locationSchemas";
import { handleSupabaseError } from "../utils/supabaseErrors";
import { supabaseAdmin } from "./supabaseService";

type LocationRecord = {
  id: string;
  organization_id: string;
  name: string;
  address_line_1: string;
  address_line_2: string | null;
  city: string;
  region: string;
  postal_code: string;
  country: string;
  latitude: number;
  longitude: number;
  geofence_radius_meters: number;
  status: string;
  created_by: string | null;
  created_at: string;
  updated_at: string;
};

async function getAssignedLocationIds(workerId: string, organizationId: string) {
  const { data, error } = await supabaseAdmin
    .from("job_assignments")
    .select("jobs!inner(location_id)")
    .eq("organization_id", organizationId)
    .eq("worker_profile_id", workerId)
    .in("assignment_status", ["assigned", "accepted"]);

  if (error) {
    handleSupabaseError(error, "Failed to fetch assigned locations.");
  }

  return Array.from(
    new Set(
      (data ?? [])
        .map((assignment) => assignment.jobs)
        .flat()
        .map((job) => job.location_id as string),
    ),
  );
}

export async function createLocation(options: {
  organizationId: string;
  createdBy: string;
  input: CreateLocationInput;
}) {
  const { data, error } = await supabaseAdmin
    .from("locations")
    .insert({
      organization_id: options.organizationId,
      name: options.input.name,
      address_line_1: options.input.addressLine1,
      address_line_2: options.input.addressLine2,
      city: options.input.city,
      region: options.input.region,
      postal_code: options.input.postalCode,
      country: options.input.country,
      latitude: options.input.latitude,
      longitude: options.input.longitude,
      geofence_radius_meters: options.input.geofenceRadiusMeters,
      status: options.input.status,
      created_by: options.createdBy,
    })
    .select("*")
    .single<LocationRecord>();

  if (error) {
    handleSupabaseError(error, "Failed to create location.");
  }

  return data;
}

export async function listLocations(options: {
  organizationId: string;
  requesterId: string;
  requesterRole: AppRole;
}) {
  let query = supabaseAdmin
    .from("locations")
    .select("*")
    .eq("organization_id", options.organizationId)
    .order("name", { ascending: true });

  if (options.requesterRole === "field_worker") {
    const locationIds = await getAssignedLocationIds(
      options.requesterId,
      options.organizationId,
    );

    if (locationIds.length === 0) {
      return [];
    }

    query = query.in("id", locationIds);
  }

  const { data, error } = await query.returns<LocationRecord[]>();

  if (error) {
    handleSupabaseError(error, "Failed to list locations.");
  }

  return data ?? [];
}
