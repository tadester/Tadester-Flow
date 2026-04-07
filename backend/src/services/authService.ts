import jwt from "jsonwebtoken";

import type { AuthenticatedUser, JwtClaims } from "../domain/auth";
import { UnauthorizedError } from "../utils/errors";
import { getProfileById } from "./profileService";

export async function authenticateToken(token: string): Promise<AuthenticatedUser> {
  const decoded = jwt.decode(token);

  if (!decoded || typeof decoded !== "object") {
    throw new UnauthorizedError("Invalid authentication token.");
  }

  const claims = decoded as JwtClaims;

  if (!claims.sub) {
    throw new UnauthorizedError("Authentication token is missing a subject.");
  }

  const profile = await getProfileById(claims.sub);

  return {
    id: profile.id,
    email: profile.email,
    role: profile.role,
    organizationId: profile.organization_id,
    status: profile.status,
  };
}
