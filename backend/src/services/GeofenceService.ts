import { handleSupabaseError } from "../utils/supabaseErrors";
import { supabaseAdmin } from "./supabaseService";

const MAX_ACCEPTABLE_ACCURACY_METERS = 50;
const ACTIVE_ASSIGNMENT_STATUSES = ["assigned", "accepted"] as const;

export type CheckGeofenceInput = {
  workerId: string;
  latitude: number;
  longitude: number;
  accuracy_meters: number;
  timestamp: string;
};

export type GeofenceState = "inside" | "outside";

export type GeofenceEventType = "geofence_enter" | "geofence_exit";

export type GeofenceEvaluation = {
  worker_id: string;
  job_id: string | null;
  location_id: string;
  distance_meters: number;
  radius_meters: number;
  state: GeofenceState;
  event_created: GeofenceEventType | null;
};

export type CheckGeofenceResult = {
  worker_id: string;
  ignored: boolean;
  evaluations: GeofenceEvaluation[];
};

type AssignedLocation = {
  organizationId: string;
  jobId: string | null;
  locationId: string;
  latitude: number;
  longitude: number;
  geofenceRadiusMeters: number;
};

type LocationEventRecord = {
  id: string;
  worker_profile_id: string;
  location_id: string;
  event_type: GeofenceEventType;
  event_timestamp: string;
};

type InsertLocationEventInput = {
  organizationId: string;
  workerId: string;
  jobId: string | null;
  locationId: string;
  eventType: GeofenceEventType;
  timestamp: string;
  latitude: number;
  longitude: number;
  accuracyMeters: number;
};

type GeofenceDataProvider = {
  getActiveAssignedLocations(workerId: string): Promise<AssignedLocation[]>;
  getLastLocationEvent(
    workerId: string,
    locationId: string,
  ): Promise<LocationEventRecord | null>;
  insertLocationEvent(input: InsertLocationEventInput): Promise<void>;
};

type JobAssignmentRow = {
  organization_id: string;
  job_id: string;
  jobs:
    | {
        id: string;
        location_id: string;
        locations:
          | {
              id: string;
              latitude: number;
              longitude: number;
              geofence_radius_meters: number;
              status: string;
            }
          | Array<{
              id: string;
              latitude: number;
              longitude: number;
              geofence_radius_meters: number;
              status: string;
            }>;
      }
    | Array<{
        id: string;
        location_id: string;
        locations:
          | {
              id: string;
              latitude: number;
              longitude: number;
              geofence_radius_meters: number;
              status: string;
            }
          | Array<{
              id: string;
              latitude: number;
              longitude: number;
              geofence_radius_meters: number;
              status: string;
            }>;
      }>;
};

class SupabaseGeofenceDataProvider implements GeofenceDataProvider {
  async getActiveAssignedLocations(workerId: string): Promise<AssignedLocation[]> {
    const { data, error } = await supabaseAdmin
      .from("job_assignments")
      .select(
        `
          organization_id,
          job_id,
          jobs!inner(
            id,
            location_id,
            locations!inner(
              id,
              latitude,
              longitude,
              geofence_radius_meters,
              status
            )
          )
        `,
      )
      .eq("worker_profile_id", workerId)
      .in("assignment_status", [...ACTIVE_ASSIGNMENT_STATUSES]);

    if (error) {
      handleSupabaseError(error, "Failed to fetch worker geofence assignments.");
    }

    return dedupeAssignedLocations(
      (data ?? []).flatMap((row) => mapAssignmentRowToAssignedLocation(row as JobAssignmentRow)),
    );
  }

  async getLastLocationEvent(
    workerId: string,
    locationId: string,
  ): Promise<LocationEventRecord | null> {
    const { data, error } = await supabaseAdmin
      .from("location_events")
      .select("id, worker_profile_id, location_id, event_type, event_timestamp")
      .eq("worker_profile_id", workerId)
      .eq("location_id", locationId)
      .in("event_type", ["geofence_enter", "geofence_exit"])
      .order("event_timestamp", { ascending: false })
      .limit(1)
      .maybeSingle<LocationEventRecord>();

    if (error) {
      handleSupabaseError(error, "Failed to fetch prior geofence state.");
    }

    return data;
  }

  async insertLocationEvent(input: InsertLocationEventInput): Promise<void> {
    const { error } = await supabaseAdmin.from("location_events").insert({
      organization_id: input.organizationId,
      job_id: input.jobId,
      location_id: input.locationId,
      worker_profile_id: input.workerId,
      event_type: input.eventType,
      event_timestamp: input.timestamp,
      metadata: {
        latitude: input.latitude,
        longitude: input.longitude,
        accuracy_meters: input.accuracyMeters,
      },
    });

    if (error) {
      handleSupabaseError(error, "Failed to insert geofence event.");
    }
  }
}

export class GeofenceService {
  private readonly dataProvider: GeofenceDataProvider;

  constructor(dataProvider: GeofenceDataProvider = new SupabaseGeofenceDataProvider()) {
    this.dataProvider = dataProvider;
  }

  async checkGeofence(input: CheckGeofenceInput): Promise<CheckGeofenceResult> {
    if (input.accuracy_meters > MAX_ACCEPTABLE_ACCURACY_METERS) {
      return {
        worker_id: input.workerId,
        ignored: true,
        evaluations: [],
      };
    }

    const assignedLocations = await this.dataProvider.getActiveAssignedLocations(input.workerId);
    const evaluations: GeofenceEvaluation[] = [];

    for (const assignedLocation of assignedLocations) {
      const distanceMeters = calculateDistanceMeters(
        input.latitude,
        input.longitude,
        assignedLocation.latitude,
        assignedLocation.longitude,
      );

      const state: GeofenceState =
        distanceMeters <= assignedLocation.geofenceRadiusMeters ? "inside" : "outside";

      const lastEvent = await this.dataProvider.getLastLocationEvent(
        input.workerId,
        assignedLocation.locationId,
      );

      const previousState = mapEventToState(lastEvent?.event_type);
      const nextEventType = determineTransitionEvent(previousState, state);

      if (nextEventType) {
        await this.dataProvider.insertLocationEvent({
          organizationId: assignedLocation.organizationId,
          workerId: input.workerId,
          jobId: assignedLocation.jobId,
          locationId: assignedLocation.locationId,
          eventType: nextEventType,
          timestamp: input.timestamp,
          latitude: input.latitude,
          longitude: input.longitude,
          accuracyMeters: input.accuracy_meters,
        });
      }

      evaluations.push({
        worker_id: input.workerId,
        job_id: assignedLocation.jobId,
        location_id: assignedLocation.locationId,
        distance_meters: distanceMeters,
        radius_meters: assignedLocation.geofenceRadiusMeters,
        state,
        event_created: nextEventType,
      });
    }

    return {
      worker_id: input.workerId,
      ignored: false,
      evaluations,
    };
  }
}

// This abstraction keeps the door open for swapping to PostGIS ST_DWithin later.
export function calculateDistanceMeters(
  fromLat: number,
  fromLng: number,
  toLat: number,
  toLng: number,
): number {
  const earthRadiusMeters = 6_371_000;
  const deltaLat = toRadians(toLat - fromLat);
  const deltaLng = toRadians(toLng - fromLng);
  const fromLatRadians = toRadians(fromLat);
  const toLatRadians = toRadians(toLat);

  const haversine =
    Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
    Math.cos(fromLatRadians) *
      Math.cos(toLatRadians) *
      Math.sin(deltaLng / 2) *
      Math.sin(deltaLng / 2);

  const centralAngle = 2 * Math.atan2(Math.sqrt(haversine), Math.sqrt(1 - haversine));

  return earthRadiusMeters * centralAngle;
}

function toRadians(value: number): number {
  return (value * Math.PI) / 180;
}

function mapEventToState(eventType: GeofenceEventType | undefined): GeofenceState | null {
  if (!eventType) {
    return null;
  }

  return eventType === "geofence_enter" ? "inside" : "outside";
}

function determineTransitionEvent(
  previousState: GeofenceState | null,
  currentState: GeofenceState,
): GeofenceEventType | null {
  if (previousState === null || previousState === currentState) {
    return null;
  }

  return currentState === "inside" ? "geofence_enter" : "geofence_exit";
}

function mapAssignmentRowToAssignedLocation(row: JobAssignmentRow): AssignedLocation[] {
  const job = Array.isArray(row.jobs) ? row.jobs[0] : row.jobs;

  if (!job) {
    return [];
  }

  const location = Array.isArray(job.locations) ? job.locations[0] : job.locations;

  if (!location || location.status !== "active") {
    return [];
  }

  return [
    {
      organizationId: row.organization_id,
      jobId: row.job_id,
      locationId: job.location_id,
      latitude: location.latitude,
      longitude: location.longitude,
      geofenceRadiusMeters: location.geofence_radius_meters,
    },
  ];
}

function dedupeAssignedLocations(locations: AssignedLocation[]): AssignedLocation[] {
  const deduped = new Map<string, AssignedLocation>();

  for (const location of locations) {
    if (!deduped.has(location.locationId)) {
      deduped.set(location.locationId, location);
    }
  }

  return Array.from(deduped.values());
}
