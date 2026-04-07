import { Client, TravelMode } from "@googlemaps/google-maps-services-js";

import { handleSupabaseError } from "../utils/supabaseErrors";
import { supabaseAdmin } from "./supabaseService";

const ACTIVE_ASSIGNMENT_STATUSES = ["assigned", "accepted"] as const;
const ACTIVE_JOB_STATUSES = ["scheduled", "in_progress"] as const;
const MAX_MATRIX_PAIRS_PER_BATCH = 10;

export type RouteLocation = {
  id: string;
  name: string;
  lat: number;
  lng: number;
};

export type OrderedRouteJob = {
  id: string;
  title: string;
  status: string;
  priority: string;
  scheduled_start_at: string;
  scheduled_end_at: string;
  location: RouteLocation;
};

export type RouteLeg = {
  from_job_id: string | null;
  to_job_id: string;
  distance_meters: number;
  duration_seconds: number;
  estimated_arrival: string;
};

export type DailyRouteResult = {
  ordered_jobs: OrderedRouteJob[];
  legs: RouteLeg[];
  total_distance: number;
  total_time: number;
};

type RoutingStop = {
  jobId: string | null;
  scheduledStartAt: string;
  lat: number;
  lng: number;
};

type RoutingPair = {
  from: RoutingStop;
  to: RoutingStop;
};

type RoutingJobRecord = {
  id: string;
  title: string;
  status: string;
  priority: string;
  scheduled_start_at: string;
  scheduled_end_at: string;
  location: RouteLocation;
};

type LastKnownLocation = {
  lat: number;
  lng: number;
  recordedAt: string;
};

type RoutingDataProvider = {
  getAssignedJobsForDate(workerId: string, date: string): Promise<RoutingJobRecord[]>;
  getLastKnownLocation(workerId: string): Promise<LastKnownLocation | null>;
};

type DistanceMatrixElement = {
  status: string;
  distance?: {
    value: number;
  };
  duration?: {
    value: number;
  };
};

type DistanceMatrixResponse = {
  data: {
    rows: Array<{
      elements: DistanceMatrixElement[];
    }>;
  };
};

type DistanceMatrixClient = {
  distancematrix(request: {
    params: {
      origins: string[];
      destinations: string[];
      mode: TravelMode;
      key: string;
    };
  }): Promise<DistanceMatrixResponse>;
};

type RoutingServiceOptions = {
  dataProvider?: RoutingDataProvider;
  mapsClient?: DistanceMatrixClient;
  apiKey?: string;
  now?: () => Date;
};

type JobAssignmentRow = {
  assignment_status: string;
  jobs:
    | {
        id: string;
        title: string;
        status: string;
        priority: string;
        scheduled_start_at: string;
        scheduled_end_at: string;
        locations:
          | {
              id: string;
              name: string;
              latitude: number;
              longitude: number;
            }
          | Array<{
              id: string;
              name: string;
              latitude: number;
              longitude: number;
            }>;
      }
    | Array<{
        id: string;
        title: string;
        status: string;
        priority: string;
        scheduled_start_at: string;
        scheduled_end_at: string;
        locations:
          | {
              id: string;
              name: string;
              latitude: number;
              longitude: number;
            }
          | Array<{
              id: string;
              name: string;
              latitude: number;
              longitude: number;
            }>;
      }>
    | null;
};

class SupabaseRoutingDataProvider implements RoutingDataProvider {
  async getAssignedJobsForDate(workerId: string, date: string): Promise<RoutingJobRecord[]> {
    const { startIso, endIso } = getUtcDateBounds(date);

    const { data, error } = await supabaseAdmin
      .from("job_assignments")
      .select(
        `
          assignment_status,
          jobs!inner(
            id,
            title,
            status,
            priority,
            scheduled_start_at,
            scheduled_end_at,
            locations!inner(
              id,
              name,
              latitude,
              longitude
            )
          )
        `,
      )
      .eq("worker_profile_id", workerId)
      .in("assignment_status", [...ACTIVE_ASSIGNMENT_STATUSES]);

    if (error) {
      handleSupabaseError(error, "Failed to fetch assigned jobs for routing.");
    }

    return (data ?? [])
      .flatMap((row) => mapAssignmentRowToRoutingJob(row as JobAssignmentRow))
      .filter((job) => {
        const scheduledStart = Date.parse(job.scheduled_start_at);

        return (
          ACTIVE_JOB_STATUSES.includes(job.status as (typeof ACTIVE_JOB_STATUSES)[number]) &&
          !Number.isNaN(scheduledStart) &&
          job.scheduled_start_at >= startIso &&
          job.scheduled_start_at < endIso
        );
      });
  }

  async getLastKnownLocation(workerId: string): Promise<LastKnownLocation | null> {
    const { data, error } = await supabaseAdmin
      .from("worker_location_pings")
      .select("latitude, longitude, recorded_at")
      .eq("worker_profile_id", workerId)
      .order("recorded_at", { ascending: false })
      .limit(1)
      .maybeSingle<{
        latitude: number;
        longitude: number;
        recorded_at: string;
      }>();

    if (error) {
      handleSupabaseError(error, "Failed to fetch worker location for routing.");
    }

    if (!data) {
      return null;
    }

    return {
      lat: data.latitude,
      lng: data.longitude,
      recordedAt: data.recorded_at,
    };
  }
}

export class RoutingService {
  private readonly dataProvider: RoutingDataProvider;
  private readonly mapsClient: DistanceMatrixClient;
  private readonly apiKey?: string;
  private readonly now: () => Date;

  constructor(options: RoutingServiceOptions = {}) {
    this.dataProvider = options.dataProvider ?? new SupabaseRoutingDataProvider();
    this.mapsClient = options.mapsClient ?? new Client({});
    this.apiKey = options.apiKey ?? process.env.GOOGLE_MAPS_API_KEY;
    this.now = options.now ?? (() => new Date());
  }

  async getDailyRoute(workerId: string, date: string): Promise<DailyRouteResult> {
    const orderedJobs = this.applyFutureOptimizationHook(
      [...(await this.dataProvider.getAssignedJobsForDate(workerId, date))].sort(
        (left, right) =>
          Date.parse(left.scheduled_start_at) - Date.parse(right.scheduled_start_at),
      ),
    ).map(mapRoutingJobToOrderedJob);

    const fallbackResult = createFallbackRouteResult(orderedJobs);

    if (orderedJobs.length <= 1 || !this.apiKey) {
      return fallbackResult;
    }

    const lastKnownLocation = await this.dataProvider.getLastKnownLocation(workerId);
    const stops = buildRoutingStops(orderedJobs, lastKnownLocation);
    const pairs = buildRoutingPairs(stops);

    if (pairs.length === 0) {
      return fallbackResult;
    }

    try {
      const legs = await this.fetchLegs(pairs, lastKnownLocation);

      return {
        ordered_jobs: orderedJobs,
        legs,
        total_distance: legs.reduce((sum, leg) => sum + leg.distance_meters, 0),
        total_time: legs.reduce((sum, leg) => sum + leg.duration_seconds, 0),
      };
    } catch {
      return fallbackResult;
    }
  }

  // Hook for future route optimization work such as nearest-neighbor or VRP.
  private applyFutureOptimizationHook(jobs: RoutingJobRecord[]): RoutingJobRecord[] {
    return jobs;
  }

  private async fetchLegs(
    pairs: RoutingPair[],
    lastKnownLocation: LastKnownLocation | null,
  ): Promise<RouteLeg[]> {
    const legs: RouteLeg[] = [];
    let rollingTimestampMs = lastKnownLocation
      ? this.now().getTime()
      : Date.parse(pairs[0]?.from.scheduledStartAt ?? this.now().toISOString());

    for (const batch of chunkPairs(pairs, MAX_MATRIX_PAIRS_PER_BATCH)) {
      const response = await this.mapsClient.distancematrix({
        params: {
          origins: batch.map((pair) => formatCoordinate(pair.from)),
          destinations: batch.map((pair) => formatCoordinate(pair.to)),
          mode: TravelMode.driving,
          key: this.apiKey as string,
        },
      });

      batch.forEach((pair, index) => {
        const element = response.data.rows[index]?.elements[index];

        if (
          !element ||
          element.status !== "OK" ||
          !element.distance ||
          !element.duration
        ) {
          throw new Error("Distance Matrix response did not include a valid leg.");
        }

        rollingTimestampMs += element.duration.value * 1000;

        legs.push({
          from_job_id: pair.from.jobId,
          to_job_id: pair.to.jobId as string,
          distance_meters: element.distance.value,
          duration_seconds: element.duration.value,
          estimated_arrival: new Date(rollingTimestampMs).toISOString(),
        });
      });
    }

    return legs;
  }
}

function mapAssignmentRowToRoutingJob(row: JobAssignmentRow): RoutingJobRecord[] {
  if (!row.jobs) {
    return [];
  }

  const job = Array.isArray(row.jobs) ? row.jobs[0] : row.jobs;

  if (!job) {
    return [];
  }

  const location = Array.isArray(job.locations)
    ? job.locations[0]
    : job.locations;

  if (!location) {
    return [];
  }

  return [
    {
      id: job.id,
      title: job.title,
      status: job.status,
      priority: job.priority,
      scheduled_start_at: job.scheduled_start_at,
      scheduled_end_at: job.scheduled_end_at,
      location: {
        id: location.id,
        name: location.name,
        lat: location.latitude,
        lng: location.longitude,
      },
    },
  ];
}

function mapRoutingJobToOrderedJob(job: RoutingJobRecord): OrderedRouteJob {
  return {
    id: job.id,
    title: job.title,
    status: job.status,
    priority: job.priority,
    scheduled_start_at: job.scheduled_start_at,
    scheduled_end_at: job.scheduled_end_at,
    location: job.location,
  };
}

function createFallbackRouteResult(orderedJobs: OrderedRouteJob[]): DailyRouteResult {
  return {
    ordered_jobs: orderedJobs,
    legs: [],
    total_distance: 0,
    total_time: 0,
  };
}

function buildRoutingStops(
  orderedJobs: OrderedRouteJob[],
  lastKnownLocation: LastKnownLocation | null,
): RoutingStop[] {
  const jobStops = orderedJobs.map<RoutingStop>((job) => ({
    jobId: job.id,
    scheduledStartAt: job.scheduled_start_at,
    lat: job.location.lat,
    lng: job.location.lng,
  }));

  if (!lastKnownLocation) {
    return jobStops;
  }

  return [
    {
      jobId: null,
      scheduledStartAt: orderedJobs[0]?.scheduled_start_at ?? lastKnownLocation.recordedAt,
      lat: lastKnownLocation.lat,
      lng: lastKnownLocation.lng,
    },
    ...jobStops,
  ];
}

function buildRoutingPairs(stops: RoutingStop[]): RoutingPair[] {
  const pairs: RoutingPair[] = [];

  for (let index = 0; index < stops.length - 1; index += 1) {
    pairs.push({
      from: stops[index],
      to: stops[index + 1],
    });
  }

  return pairs;
}

function formatCoordinate(stop: RoutingStop): string {
  return `${stop.lat},${stop.lng}`;
}

function chunkPairs(pairs: RoutingPair[], size: number): RoutingPair[][] {
  const chunks: RoutingPair[][] = [];

  for (let index = 0; index < pairs.length; index += size) {
    chunks.push(pairs.slice(index, index + size));
  }

  return chunks;
}

function getUtcDateBounds(date: string): { startIso: string; endIso: string } {
  const start = new Date(`${date}T00:00:00.000Z`);

  if (Number.isNaN(start.getTime())) {
    throw new Error(`Invalid route date: ${date}`);
  }

  const end = new Date(start);
  end.setUTCDate(end.getUTCDate() + 1);

  return {
    startIso: start.toISOString(),
    endIso: end.toISOString(),
  };
}
