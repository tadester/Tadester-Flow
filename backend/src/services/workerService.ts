import type { AppRole } from "../domain/auth";
import { ForbiddenError, NotFoundError } from "../utils/errors";
import { handleSupabaseError } from "../utils/supabaseErrors";
import { supabaseAdmin } from "./supabaseService";

type WorkerStatusOptions = {
  organizationId: string;
  requesterId: string;
  requesterRole: AppRole;
  workerId: string;
};

const ACTIVE_ASSIGNMENT_STATUSES = ["assigned", "accepted"] as const;
const ACTIVE_PING_WINDOW_MS = 15 * 60 * 1000;

export async function getWorkerStatus(options: WorkerStatusOptions) {
  if (
    options.requesterRole === "field_worker" &&
    options.requesterId !== options.workerId
  ) {
    throw new ForbiddenError("Field workers can only view their own status.");
  }

  const { data: latestPing, error: latestPingError } = await supabaseAdmin
    .from("worker_location_pings")
    .select("worker_profile_id, latitude, longitude, accuracy_meters, recorded_at")
    .eq("organization_id", options.organizationId)
    .eq("worker_profile_id", options.workerId)
    .order("recorded_at", { ascending: false })
    .limit(1)
    .maybeSingle<{
      worker_profile_id: string;
      latitude: number;
      longitude: number;
      accuracy_meters: number | null;
      recorded_at: string;
    }>();

  if (latestPingError) {
    handleSupabaseError(latestPingError, "Failed to fetch worker status.");
  }

  const { data: assignment, error: assignmentError } = await supabaseAdmin
    .from("job_assignments")
    .select(
      "job_id, assignment_status, jobs!inner(id, title, status, priority, scheduled_start_at, scheduled_end_at, location_id)",
    )
    .eq("organization_id", options.organizationId)
    .eq("worker_profile_id", options.workerId)
    .in("assignment_status", [...ACTIVE_ASSIGNMENT_STATUSES])
    .order("assigned_at", { ascending: false })
    .limit(1)
    .maybeSingle<{
      job_id: string;
      assignment_status: string;
      jobs: {
        id: string;
        title: string;
        status: string;
        priority: string;
        scheduled_start_at: string;
        scheduled_end_at: string;
        location_id: string;
      };
    }>();

  if (assignmentError) {
    handleSupabaseError(assignmentError, "Failed to fetch worker assignment.");
  }

  if (!latestPing && !assignment) {
    throw new NotFoundError("Worker status not found.");
  }

  const lastPing = latestPing
    ? {
        lat: latestPing.latitude,
        lng: latestPing.longitude,
        accuracy: latestPing.accuracy_meters,
        timestamp: latestPing.recorded_at,
      }
    : null;

  const currentJob = assignment
    ? {
        id: assignment.jobs.id,
        title: assignment.jobs.title,
        status: assignment.jobs.status,
        priority: assignment.jobs.priority,
        location_id: assignment.jobs.location_id,
        scheduled_start_at: assignment.jobs.scheduled_start_at,
        scheduled_end_at: assignment.jobs.scheduled_end_at,
      }
    : null;

  const status =
    latestPing &&
    Date.now() - new Date(latestPing.recorded_at).getTime() <= ACTIVE_PING_WINDOW_MS
      ? "active"
      : "inactive";

  return {
    worker_id: options.workerId,
    last_ping: lastPing,
    current_job: currentJob,
    status,
  };
}
