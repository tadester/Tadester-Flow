import type { Request, Response } from "express";

import { RoutingService } from "../services/RoutingService";
import { getWorkerStatus } from "../services/workerService";
import { BadRequestError } from "../utils/errors";
import { getAuthenticatedUser, getParamValue } from "../utils/requestContext";

const routingService = new RoutingService();

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

export async function getCurrentWorkerRouteController(
  request: Request,
  response: Response,
) {
  const user = getAuthenticatedUser(request);
  const route = await routingService.getDailyRoute(
    user.id,
    getRouteDate(request),
  );

  response.status(200).json({ data: route });
}

export async function getWorkerRouteController(
  request: Request,
  response: Response,
) {
  const user = getAuthenticatedUser(request);
  const workerId = getParamValue(request.params.id, "worker id");
  const effectiveWorkerId = user.role === "field_worker" ? user.id : workerId;
  const route = await routingService.getDailyRoute(
    effectiveWorkerId,
    getRouteDate(request),
  );

  response.status(200).json({ data: route });
}

function getRouteDate(request: Request): string {
  const rawDate =
    typeof request.query.date === "string" ? request.query.date : undefined;

  if (!rawDate) {
    return new Date().toISOString().slice(0, 10);
  }

  if (!/^\d{4}-\d{2}-\d{2}$/.test(rawDate)) {
    throw new BadRequestError("Route date must be in YYYY-MM-DD format.");
  }

  return rawDate;
}
