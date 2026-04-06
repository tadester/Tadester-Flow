import type { Request, Response } from "express";

import { getWorkerStatus } from "../services/workerService";
import { getAuthenticatedUser, getParamValue } from "../utils/requestContext";

export async function getWorkerStatusController(
  request: Request,
  response: Response,
) {
  const user = getAuthenticatedUser(request);
  const workerStatus = await getWorkerStatus({
    organizationId: user.organizationId,
    requesterId: user.id,
    requesterRole: user.role,
    workerId: getParamValue(request.params.id, "worker id"),
  });

  response.status(200).json({ data: workerStatus });
}
