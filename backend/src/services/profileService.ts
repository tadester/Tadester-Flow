import { NotFoundError } from "../utils/errors";
import { handleSupabaseError } from "../utils/supabaseErrors";
import { supabaseAdmin } from "./supabaseService";

export type ProfileRecord = {
  id: string;
  email: string;
  role: "admin" | "dispatcher" | "operator" | "field_worker";
  organization_id: string;
  status: "active" | "inactive";
};

export async function getProfileById(profileId: string): Promise<ProfileRecord> {
  const { data, error } = await supabaseAdmin
    .from("profiles")
    .select("id, email, role, organization_id, status")
    .eq("id", profileId)
    .single<ProfileRecord>();

  if (error) {
    handleSupabaseError(error, "Failed to fetch profile.");
  }

  if (!data) {
    throw new NotFoundError("Profile not found.");
  }

  return data;
}

export async function updateProfileStatus(profileId: string, status: "active" | "inactive") {
  const { error } = await supabaseAdmin
    .from("profiles")
    .update({ status })
    .eq("id", profileId);

  if (error) {
    handleSupabaseError(error, "Failed to update profile status.");
  }
}
