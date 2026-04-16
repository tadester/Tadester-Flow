import type { Request, Response } from "express";

import type {
  CreateJobInput,
  JobStatusInput,
  WorkerJobActionInput,
} from "../schemas/jobSchemas";
import {
  createJob,
  getJobById,
  listJobs,
  performWorkerJobAction,
  updateJobStatus,
} from "../services/jobService";
import {
  getAuthenticatedUser,
  getParamValue,
  getValidatedBody,
} from "../utils/requestContext";

export async function createJobController(
  request: Request,
  response: Response,
) {
  const user = getAuthenticatedUser(request);
  const job = await createJob({
    organizationId: user.organizationId,
    createdBy: user.id,
    input: getValidatedBody<CreateJobInput>(request),
  });

  response.status(201).json({ data: job });
}

export async function listJobsController(
  request: Request,
  response: Response,
) {
  const user = getAuthenticatedUser(request);
  const workerId =
    user.role === "field_worker"
      ? user.id
      : typeof request.query.worker_id === "string"
        ? request.query.worker_id
        : undefined;

  const jobs = await listJobs({
    organizationId: user.organizationId,
    requesterId: user.id,
    requesterRole: user.role,
    workerId,
  });

  response.status(200).json({ data: jobs });
}

export async function getJobDetailsController(
  request: Request,
  response: Response,
) {
  const user = getAuthenticatedUser(request);
  const job = await getJobById({
    organizationId: user.organizationId,
    requesterId: user.id,
    requesterRole: user.role,
    jobId: getParamValue(request.params.id, "job id"),
  });

  response.status(200).json({ data: job });
}

export async function updateJobStatusController(
  request: Request,
  response: Response,
) {
  const user = getAuthenticatedUser(request);
  const { status } = getValidatedBody<JobStatusInput>(request);

  const job = await updateJobStatus({
    organizationId: user.organizationId,
    jobId: getParamValue(request.params.id, "job id"),
    status,
  });

  response.status(200).json({ data: job });
}

export async function workerJobActionController(
  request: Request,
  response: Response,
) {
  const user = getAuthenticatedUser(request);
  const payload = getValidatedBody<WorkerJobActionInput>(request);

  const job = await performWorkerJobAction({
    organizationId: user.organizationId,
    workerId: user.id,
    jobId: getParamValue(request.params.id, "job id"),
    input: payload,
  });

  response.status(200).json({ data: job });
}
