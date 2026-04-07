import type { AuthenticatedUser, JwtClaims } from "../domain/auth";
import { UnauthorizedError } from "../utils/errors";
import { getProfileById } from "./profileService";
import { supabaseAdmin } from "./supabaseService";

export async function authenticateToken(token: string): Promise<AuthenticatedUser> {
  const { data, error } = await supabaseAdmin.auth.getUser(token);

  if (error || !data.user) {
    throw new UnauthorizedError("Invalid or expired authentication token.");
  }

  const claims = data.user as unknown as JwtClaims;

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
