import type { Request, Response } from "express";

import { getOrganizationWorkspace } from "../services/organizationService";
import { getAuthenticatedUser } from "../utils/requestContext";

export async function getOrganizationWorkspaceController(
  request: Request,
  response: Response,
) {
  const user = getAuthenticatedUser(request);
  const workspace = await getOrganizationWorkspace({
    organizationId: user.organizationId,
    profileId: user.id,
  });

  response.status(200).json({ data: workspace });
}
