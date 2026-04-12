import type {
  CreateJobInput,
  JobStatusInput,
  WorkerJobActionInput,
} from "../schemas/jobSchemas";
import type { AppRole } from "../domain/auth";
import { NotFoundError } from "../utils/errors";
import { handleSupabaseError } from "../utils/supabaseErrors";
import { supabaseAdmin } from "./supabaseService";

const ACTIVE_ASSIGNMENT_STATUSES = ["assigned", "accepted"] as const;

type JobRecord = {
  id: string;
  organization_id: string;
  location_id: string;
  title: string;
  description: string | null;
  status: string;
  priority: string;
  scheduled_start_at: string;
  scheduled_end_at: string;
  created_by: string | null;
  created_at: string;
  updated_at: string;
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
      }>
    | null;
};

type JobResponse = {
  id: string;
  organization_id: string;
  location_id: string;
  location_name: string | null;
  latitude: number | null;
  longitude: number | null;
  title: string;
  description: string | null;
  status: string;
  priority: string;
  scheduled_start_at: string;
  scheduled_end_at: string;
  created_by: string | null;
  created_at: string;
  updated_at: string;
};

type JobListOptions = {
  organizationId: string;
  requesterId: string;
  requesterRole: AppRole;
  workerId?: string;
};

type WorkerAccessibleJobRecord = JobRecord & {
  job_assignments:
    | Array<{
        worker_profile_id: string;
        assignment_status: string;
      }>
    | null;
};

async function getAssignedJobIds(workerId: string, organizationId: string) {
  const { data, error } = await supabaseAdmin
    .from("job_assignments")
    .select("job_id")
    .eq("organization_id", organizationId)
    .eq("worker_profile_id", workerId)
    .in("assignment_status", [...ACTIVE_ASSIGNMENT_STATUSES]);

  if (error) {
    handleSupabaseError(error, "Failed to fetch job assignments.");
  }

  return (data ?? []).map((assignment) => assignment.job_id as string);
}

export async function createJob(options: {
  organizationId: string;
  createdBy: string;
  input: CreateJobInput;
}) {
  const { data, error } = await supabaseAdmin
    .from("jobs")
    .insert({
      organization_id: options.organizationId,
      location_id: options.input.locationId,
      title: options.input.title,
      description: options.input.description,
      status: options.input.status,
      priority: options.input.priority,
      scheduled_start_at: options.input.scheduledStartAt,
      scheduled_end_at: options.input.scheduledEndAt,
      created_by: options.createdBy,
    })
    .select(
      `
        *,
        locations(
          id,
          name,
          latitude,
          longitude
        )
      `,
    )
    .single<JobRecord>();

  if (error) {
    handleSupabaseError(error, "Failed to create job.");
  }

  return data ? mapJobRecord(data) : data;
}

export async function listJobs(options: JobListOptions) {
  let query = supabaseAdmin
    .from("jobs")
    .select(
      `
        *,
        locations(
          id,
          name,
          latitude,
          longitude
        )
      `,
    )
    .eq("organization_id", options.organizationId)
    .order("scheduled_start_at", { ascending: true });

  if (options.workerId) {
    const jobIds = await getAssignedJobIds(options.workerId, options.organizationId);

    if (jobIds.length === 0) {
      return [];
    }

    query = query.in("id", jobIds);
  }

  const { data, error } = await query.returns<JobRecord[]>();

  if (error) {
    handleSupabaseError(error, "Failed to list jobs.");
  }

  return (data ?? []).map(mapJobRecord);
}

export async function getJobById(options: {
  organizationId: string;
  requesterId: string;
  requesterRole: AppRole;
  jobId: string;
}) {
  if (options.requesterRole === "field_worker") {
    const jobIds = await getAssignedJobIds(options.requesterId, options.organizationId);

    if (!jobIds.includes(options.jobId)) {
      throw new NotFoundError("Job not found.");
    }
  }

  const { data, error } = await supabaseAdmin
    .from("jobs")
    .select(
      `
        *,
        locations(
          id,
          name,
          latitude,
          longitude
        )
      `,
    )
    .eq("organization_id", options.organizationId)
    .eq("id", options.jobId)
    .single<JobRecord>();

  if (error) {
    handleSupabaseError(error, "Failed to fetch job.");
  }

  if (!data) {
    throw new NotFoundError("Job not found.");
  }

  return mapJobRecord(data);
}

export async function updateJobStatus(options: {
  organizationId: string;
  jobId: string;
  status: JobStatusInput["status"];
}) {
  const data = await updateJobRecordStatus({
    organizationId: options.organizationId,
    jobId: options.jobId,
    status: options.status,
  });

  return mapJobRecord(data);
}

export async function performWorkerJobAction(options: {
  organizationId: string;
  workerId: string;
  jobId: string;
  input: WorkerJobActionInput;
}) {
  await getWorkerAccessibleJob(options);

  if (options.input.action === "start") {
    const job = await updateJobRecordStatus({
      organizationId: options.organizationId,
      jobId: options.jobId,
      status: "in_progress",
    });

    await insertLocationEvent({
      organizationId: options.organizationId,
      jobId: options.jobId,
      locationId: job.location_id,
      workerId: options.workerId,
      eventType: "job_started",
      metadata: buildWorkerActionMetadata(options.input),
    });

    return mapJobRecord(job);
  }

  if (options.input.action === "complete") {
    const job = await updateJobRecordStatus({
      organizationId: options.organizationId,
      jobId: options.jobId,
      status: "completed",
    });

    await insertLocationEvent({
      organizationId: options.organizationId,
      jobId: options.jobId,
      locationId: job.location_id,
      workerId: options.workerId,
      eventType: "job_completed",
      metadata: buildWorkerActionMetadata(options.input),
    });

    return mapJobRecord(job);
  }

  const job = await updateJobRecordStatus({
    organizationId: options.organizationId,
    jobId: options.jobId,
    status: "cancelled",
  });

  await insertLocationEvent({
    organizationId: options.organizationId,
    jobId: options.jobId,
    locationId: job.location_id,
    workerId: options.workerId,
    eventType: "job_completed",
    metadata: {
      ...buildWorkerActionMetadata(options.input),
      outcome: "unable_to_complete",
    },
  });

  return mapJobRecord(job);
}

async function getWorkerAccessibleJob(options: {
  organizationId: string;
  workerId: string;
  jobId: string;
}) {
  const { data, error } = await supabaseAdmin
    .from("jobs")
    .select(
      `
        *,
        locations(
          id,
          name,
          latitude,
          longitude
        ),
        job_assignments(
          worker_profile_id,
          assignment_status
        )
      `,
    )
    .eq("organization_id", options.organizationId)
    .eq("id", options.jobId)
    .eq("job_assignments.worker_profile_id", options.workerId)
    .in("job_assignments.assignment_status", [...ACTIVE_ASSIGNMENT_STATUSES])
    .single<WorkerAccessibleJobRecord>();

  if (error) {
    handleSupabaseError(error, "Failed to fetch worker job.");
  }

  if (!data) {
    throw new NotFoundError("Job not found.");
  }

  return data;
}

async function updateJobRecordStatus(options: {
  organizationId: string;
  jobId: string;
  status: JobStatusInput["status"];
}) {
  const { data, error } = await supabaseAdmin
    .from("jobs")
    .update({ status: options.status })
    .eq("organization_id", options.organizationId)
    .eq("id", options.jobId)
    .select(
      `
        *,
        locations(
          id,
          name,
          latitude,
          longitude
        )
      `,
    )
    .single<JobRecord>();

  if (error) {
    handleSupabaseError(error, "Failed to update job status.");
  }

  if (!data) {
    throw new NotFoundError("Job not found.");
  }

  return data;
}

async function insertLocationEvent(options: {
  organizationId: string;
  jobId: string;
  locationId: string;
  workerId: string;
  eventType: "job_started" | "job_completed";
  metadata: Record<string, string>;
}) {
  const { error } = await supabaseAdmin.from("location_events").insert({
    organization_id: options.organizationId,
    job_id: options.jobId,
    location_id: options.locationId,
    worker_profile_id: options.workerId,
    event_type: options.eventType,
    event_timestamp: new Date().toISOString(),
    metadata: options.metadata,
  });

  if (error) {
    handleSupabaseError(error, "Failed to record worker job event.");
  }
}

function buildWorkerActionMetadata(
  input: WorkerJobActionInput,
): Record<string, string> {
  const metadata: Record<string, string> = {
    source: "worker_mobile",
    action: input.action,
  };

  if (input.notes) {
    metadata.notes = input.notes;
  }

  if (input.reason) {
    metadata.reason = input.reason;
  }

  return metadata;
}

function mapJobRecord(record: JobRecord): JobResponse {
  const location = Array.isArray(record.locations)
    ? record.locations[0]
    : record.locations;

  return {
    id: record.id,
    organization_id: record.organization_id,
    location_id: record.location_id,
    location_name: location?.name ?? null,
    latitude: location?.latitude ?? null,
    longitude: location?.longitude ?? null,
    title: record.title,
    description: record.description,
    status: record.status,
    priority: record.priority,
    scheduled_start_at: record.scheduled_start_at,
    scheduled_end_at: record.scheduled_end_at,
    created_by: record.created_by,
    created_at: record.created_at,
    updated_at: record.updated_at,
  };
}
