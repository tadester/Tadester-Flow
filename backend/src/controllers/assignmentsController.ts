import type { Request, Response } from "express";

import type { CreateAssignmentInput } from "../schemas/assignmentSchemas";
import type { AutoAssignJobsInput } from "../schemas/autoAssignmentSchemas";
import { createAssignment } from "../services/assignmentService";
import { autoAssignJobs } from "../services/autoAssignmentService";
import { getAuthenticatedUser, getValidatedBody } from "../utils/requestContext";

export async function createAssignmentController(
  request: Request,
  response: Response,
) {
  const user = getAuthenticatedUser(request);
  const assignment = await createAssignment({
    organizationId: user.organizationId,
    assignedBy: user.id,
    input: getValidatedBody<CreateAssignmentInput>(request),
  });

  response.status(201).json({ data: assignment });
}

export async function autoAssignJobsController(
  request: Request,
  response: Response,
) {
  const user = getAuthenticatedUser(request);
  const result = await autoAssignJobs({
    organizationId: user.organizationId,
    assignedBy: user.id,
    input: getValidatedBody<AutoAssignJobsInput>(request),
  });

  response.status(200).json({ data: result });
}
