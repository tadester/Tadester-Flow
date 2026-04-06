import type { CreateAssignmentInput } from "../schemas/assignmentSchemas";
import { handleSupabaseError } from "../utils/supabaseErrors";
import { supabaseAdmin } from "./supabaseService";

type AssignmentRecord = {
  id: string;
  organization_id: string;
  job_id: string;
  worker_profile_id: string;
  assignment_status: string;
  assigned_at: string;
  assigned_by: string | null;
  created_at: string;
  updated_at: string;
};

export async function createAssignment(options: {
  organizationId: string;
  assignedBy: string;
  input: CreateAssignmentInput;
}) {
  const { data, error } = await supabaseAdmin
    .from("job_assignments")
    .insert({
      organization_id: options.organizationId,
      job_id: options.input.jobId,
      worker_profile_id: options.input.workerProfileId,
      assignment_status: options.input.assignmentStatus,
      assigned_at: new Date().toISOString(),
      assigned_by: options.assignedBy,
    })
    .select("*")
    .single<AssignmentRecord>();

  if (error) {
    handleSupabaseError(error, "Failed to create assignment.");
  }

  return data;
}
