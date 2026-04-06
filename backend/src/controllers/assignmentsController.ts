import type { Request, Response } from "express";

import type { CreateAssignmentInput } from "../schemas/assignmentSchemas";
import { createAssignment } from "../services/assignmentService";
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
