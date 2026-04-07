import { calculateDistanceMeters } from "./GeofenceService";
import { createAssignment } from "./assignmentService";
import { handleSupabaseError } from "../utils/supabaseErrors";
import { NotFoundError } from "../utils/errors";
import { supabaseAdmin } from "./supabaseService";

const ACTIVE_JOB_STATUSES = ["scheduled", "in_progress"] as const;
const ACTIVE_ASSIGNMENT_STATUSES = ["assigned", "accepted"] as const;
const ACTIVE_WORKER_WINDOW_MS = 15 * 60 * 1000;
const ASSIGNMENT_LOAD_PENALTY_METERS = 5000;

type AutoAssignableJob = {
  id: string;
  title: string;
  scheduledStartAt: string;
  location: {
    id: string;
    name: string;
    latitude: number;
    longitude: number;
  };
};

type ActiveWorkerCandidate = {
  id: string;
  fullName: string;
  email: string;
  latitude: number;
  longitude: number;
  recordedAt: string;
  activeAssignmentsCount: number;
};

type PlannedAssignment = {
  jobId: string;
  workerProfileId: string;
  distanceMeters: number;
  score: number;
};

export type AutoAssignResult = {
  assignments_created: Array<{
    job_id: string;
    worker_profile_id: string;
    worker_name: string;
    distance_meters: number;
  }>;
  skipped_jobs: Array<{
    job_id: string;
    reason: string;
  }>;
};

export async function autoAssignJobs(options: {
  organizationId: string;
  assignedBy: string;
  input: {
    jobId?: string;
  };
}) : Promise<AutoAssignResult> {
  const jobs = await getAutoAssignableJobs(options.organizationId, options.input.jobId);
  const workers = await getActiveWorkerCandidates(options.organizationId);

  if (options.input.jobId && jobs.length === 0) {
    throw new NotFoundError("Job not found or is not eligible for auto-assignment.");
  }

  if (jobs.length === 0) {
    return { assignments_created: [], skipped_jobs: [] };
  }

  if (workers.length === 0) {
    return {
      assignments_created: [],
      skipped_jobs: jobs.map((job) => ({
        job_id: job.id,
        reason: "No active workers with recent location data are available.",
      })),
    };
  }

  const plans = planAssignmentsByProximity(jobs, workers);
  const workerMap = new Map(workers.map((worker) => [worker.id, worker]));
  const assignmentsCreated: AutoAssignResult["assignments_created"] = [];

  for (const plan of plans.assignments) {
    await createAssignment({
      organizationId: options.organizationId,
      assignedBy: options.assignedBy,
      input: {
        jobId: plan.jobId,
        workerProfileId: plan.workerProfileId,
        assignmentStatus: "assigned",
      },
    });

    const worker = workerMap.get(plan.workerProfileId);
    assignmentsCreated.push({
      job_id: plan.jobId,
      worker_profile_id: plan.workerProfileId,
      worker_name: worker?.fullName ?? worker?.email ?? "Assigned worker",
      distance_meters: Math.round(plan.distanceMeters),
    });
  }

  return {
    assignments_created: assignmentsCreated,
    skipped_jobs: plans.skippedJobs,
  };
}

export function planAssignmentsByProximity(
  jobs: AutoAssignableJob[],
  workers: ActiveWorkerCandidate[],
): {
  assignments: PlannedAssignment[];
  skippedJobs: Array<{ job_id: string; reason: string }>;
} {
  const assignmentLoads = new Map<string, number>(
    workers.map((worker) => [worker.id, worker.activeAssignmentsCount]),
  );

  const assignments: PlannedAssignment[] = [];
  const skippedJobs: Array<{ job_id: string; reason: string }> = [];

  for (const job of sortJobsForAssignment(jobs)) {
    let bestPlan: PlannedAssignment | null = null;

    for (const worker of workers) {
      const load = assignmentLoads.get(worker.id) ?? 0;
      const distanceMeters = calculateDistanceMeters(
        worker.latitude,
        worker.longitude,
        job.location.latitude,
        job.location.longitude,
      );
      const score = distanceMeters + load * ASSIGNMENT_LOAD_PENALTY_METERS;

      if (
        !bestPlan ||
        score < bestPlan.score ||
        (score === bestPlan.score && worker.id < bestPlan.workerProfileId)
      ) {
        bestPlan = {
          jobId: job.id,
          workerProfileId: worker.id,
          distanceMeters,
          score,
        };
      }
    }

    if (!bestPlan) {
      skippedJobs.push({
        job_id: job.id,
        reason: "No worker candidate was available for this job.",
      });
      continue;
    }

    assignments.push(bestPlan);
    assignmentLoads.set(
      bestPlan.workerProfileId,
      (assignmentLoads.get(bestPlan.workerProfileId) ?? 0) + 1,
    );
  }

  return { assignments, skippedJobs };
}

function sortJobsForAssignment(jobs: AutoAssignableJob[]) {
  return [...jobs].sort((left, right) => {
    const leftTime = Date.parse(left.scheduledStartAt);
    const rightTime = Date.parse(right.scheduledStartAt);

    if (Number.isNaN(leftTime) && Number.isNaN(rightTime)) {
      return left.id.localeCompare(right.id);
    }

    if (Number.isNaN(leftTime)) {
      return 1;
    }

    if (Number.isNaN(rightTime)) {
      return -1;
    }

    if (leftTime !== rightTime) {
      return leftTime - rightTime;
    }

    return left.id.localeCompare(right.id);
  });
}

async function getAutoAssignableJobs(organizationId: string, jobId?: string) {
  let query = supabaseAdmin
    .from("jobs")
    .select(
      `
        id,
        title,
        scheduled_start_at,
        status,
        locations!inner(
          id,
          name,
          latitude,
          longitude
        )
      `,
    )
    .eq("organization_id", organizationId)
    .in("status", [...ACTIVE_JOB_STATUSES]);

  if (jobId) {
    query = query.eq("id", jobId);
  }

  const { data, error } = await query;

  if (error) {
    handleSupabaseError(error, "Failed to fetch jobs for auto-assignment.");
  }

  const jobRows = (data ?? []) as Array<{
    id: string;
    title: string;
    scheduled_start_at: string;
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
  }>;

  const activeAssignments = await getActiveAssignmentsByJobId(
    organizationId,
    jobRows.map((job) => job.id),
  );

  return jobRows
    .filter((job) => !activeAssignments.has(job.id))
    .map((job) => {
      const location = Array.isArray(job.locations)
        ? job.locations[0]
        : job.locations;

      return {
        id: job.id,
        title: job.title,
        scheduledStartAt: job.scheduled_start_at,
        location: {
          id: location.id,
          name: location.name,
          latitude: location.latitude,
          longitude: location.longitude,
        },
      };
    });
}

async function getActiveAssignmentsByJobId(
  organizationId: string,
  jobIds: string[],
): Promise<Set<string>> {
  if (jobIds.length === 0) {
    return new Set<string>();
  }

  const { data, error } = await supabaseAdmin
    .from("job_assignments")
    .select("job_id")
    .eq("organization_id", organizationId)
    .in("assignment_status", [...ACTIVE_ASSIGNMENT_STATUSES])
    .in("job_id", jobIds);

  if (error) {
    handleSupabaseError(error, "Failed to fetch active assignments.");
  }

  return new Set((data ?? []).map((row) => row.job_id as string));
}

async function getActiveWorkerCandidates(
  organizationId: string,
): Promise<ActiveWorkerCandidate[]> {
  const { data: workers, error: workerError } = await supabaseAdmin
    .from("profiles")
    .select("id, full_name, email")
    .eq("organization_id", organizationId)
    .eq("role", "field_worker")
    .eq("status", "active");

  if (workerError) {
    handleSupabaseError(workerError, "Failed to fetch workers for auto-assignment.");
  }

  const workerRows = (workers ?? []) as Array<{
    id: string;
    full_name: string | null;
    email: string;
  }>;

  if (workerRows.length === 0) {
    return [];
  }

  const workerIds = workerRows.map((worker) => worker.id);
  const cutoff = new Date(Date.now() - ACTIVE_WORKER_WINDOW_MS).toISOString();

  const [pingsResult, assignmentCountsResult] = await Promise.all([
    supabaseAdmin
      .from("worker_location_pings")
      .select("worker_profile_id, latitude, longitude, recorded_at")
      .eq("organization_id", organizationId)
      .in("worker_profile_id", workerIds)
      .gte("recorded_at", cutoff)
      .order("recorded_at", { ascending: false }),
    supabaseAdmin
      .from("job_assignments")
      .select("worker_profile_id")
      .eq("organization_id", organizationId)
      .in("worker_profile_id", workerIds)
      .in("assignment_status", [...ACTIVE_ASSIGNMENT_STATUSES]),
  ]);

  if (pingsResult.error) {
    handleSupabaseError(pingsResult.error, "Failed to fetch worker locations.");
  }

  if (assignmentCountsResult.error) {
    handleSupabaseError(
      assignmentCountsResult.error,
      "Failed to fetch worker assignment counts.",
    );
  }

  const latestPingByWorker = new Map<string, {
    latitude: number;
    longitude: number;
    recorded_at: string;
  }>();

  for (const row of (pingsResult.data ?? []) as Array<{
    worker_profile_id: string;
    latitude: number;
    longitude: number;
    recorded_at: string;
  }>) {
    if (!latestPingByWorker.has(row.worker_profile_id)) {
      latestPingByWorker.set(row.worker_profile_id, row);
    }
  }

  const assignmentCounts = new Map<string, number>();
  for (const row of (assignmentCountsResult.data ?? []) as Array<{ worker_profile_id: string }>) {
    assignmentCounts.set(
      row.worker_profile_id,
      (assignmentCounts.get(row.worker_profile_id) ?? 0) + 1,
    );
  }

  return workerRows
    .map((worker) => {
      const ping = latestPingByWorker.get(worker.id);
      if (!ping) {
        return null;
      }

      return {
        id: worker.id,
        fullName: worker.full_name ?? worker.email,
        email: worker.email,
        latitude: ping.latitude,
        longitude: ping.longitude,
        recordedAt: ping.recorded_at,
        activeAssignmentsCount: assignmentCounts.get(worker.id) ?? 0,
      } satisfies ActiveWorkerCandidate;
    })
    .filter((worker): worker is ActiveWorkerCandidate => worker != null);
}
