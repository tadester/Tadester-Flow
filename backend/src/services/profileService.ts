import { NotFoundError } from "../utils/errors";
import { handleSupabaseError } from "../utils/supabaseErrors";
import { supabaseAdmin } from "./supabaseService";

type ProfileRecord = {
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

  if (!data || data.status !== "active") {
    throw new NotFoundError("Active profile not found.");
  }

  return data;
}
