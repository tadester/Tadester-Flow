import type { Request, Response } from "express";

import type { CreateLocationInput } from "../schemas/locationSchemas";
import { createLocation, listLocations } from "../services/locationService";
import { getAuthenticatedUser, getValidatedBody } from "../utils/requestContext";

export async function createLocationController(
  request: Request,
  response: Response,
) {
  const user = getAuthenticatedUser(request);
  const location = await createLocation({
    organizationId: user.organizationId,
    createdBy: user.id,
    input: getValidatedBody<CreateLocationInput>(request),
  });

  response.status(201).json({ data: location });
}

export async function listLocationsController(
  request: Request,
  response: Response,
) {
  const user = getAuthenticatedUser(request);
  const locations = await listLocations({
    organizationId: user.organizationId,
    requesterId: user.id,
    requesterRole: user.role,
  });

  response.status(200).json({ data: locations });
}
