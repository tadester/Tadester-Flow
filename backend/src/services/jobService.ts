import type {
  CreateJobInput,
  JobStatusInput,
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
};

type JobListOptions = {
  organizationId: string;
  requesterId: string;
  requesterRole: AppRole;
  workerId?: string;
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
    .select("*")
    .single<JobRecord>();

  if (error) {
    handleSupabaseError(error, "Failed to create job.");
  }

  return data;
}

export async function listJobs(options: JobListOptions) {
  let query = supabaseAdmin
    .from("jobs")
    .select("*")
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

  return data ?? [];
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
    .select("*")
    .eq("organization_id", options.organizationId)
    .eq("id", options.jobId)
    .single<JobRecord>();

  if (error) {
    handleSupabaseError(error, "Failed to fetch job.");
  }

  if (!data) {
    throw new NotFoundError("Job not found.");
  }

  return data;
}

export async function updateJobStatus(options: {
  organizationId: string;
  jobId: string;
  status: JobStatusInput["status"];
}) {
  const { data, error } = await supabaseAdmin
    .from("jobs")
    .update({ status: options.status })
    .eq("organization_id", options.organizationId)
    .eq("id", options.jobId)
    .select("*")
    .single<JobRecord>();

  if (error) {
    handleSupabaseError(error, "Failed to update job status.");
  }

  if (!data) {
    throw new NotFoundError("Job not found.");
  }

  return data;
}
