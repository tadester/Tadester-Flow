import type { Request, Response } from "express";

import { listProfilesByOrganization } from "../services/profileService";
import { getAuthenticatedUser } from "../utils/requestContext";

export async function listEmployeesController(
  request: Request,
  response: Response,
) {
  const user = getAuthenticatedUser(request);
  const employees = await listProfilesByOrganization(user.organizationId);

  response.status(200).json({ data: employees });
}
