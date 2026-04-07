import type { AuthenticatedUser } from "../domain/auth";
import { UnauthorizedError } from "../utils/errors";
import { getProfileById } from "./profileService";
import { supabaseAdmin } from "./supabaseService";

export async function authenticateToken(token: string): Promise<AuthenticatedUser> {
  const { data, error } = await supabaseAdmin.auth.getUser(token);

  if (error || !data.user) {
    throw new UnauthorizedError("Invalid or expired authentication token.");
  }

  if (!data.user.id) {
    throw new UnauthorizedError("Authentication token is missing a user id.");
  }

  const profile = await getProfileById(data.user.id);

  return {
    id: profile.id,
    email: profile.email,
    role: profile.role,
    organizationId: profile.organization_id,
    status: profile.status,
  };
}
