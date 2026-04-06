import type { Request, Response } from "express";

import type { TrackingPingInput } from "../schemas/trackingSchemas";
import { IngestionService } from "../services/IngestionService";
import { getAuthenticatedUser, getValidatedBody } from "../utils/requestContext";

const ingestionService = new IngestionService();

export async function trackingPingController(request: Request, response: Response) {
  const user = getAuthenticatedUser(request);
  const ping = getValidatedBody<TrackingPingInput>(request);

  await ingestionService.ingestPing({
    organizationId: user.organizationId,
    workerId: user.id,
    ping,
  });

  response.status(200).json({ success: true });
}
