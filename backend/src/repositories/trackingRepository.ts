import { handleSupabaseError } from "../utils/supabaseErrors";
import { supabaseAdmin } from "../services/supabaseService";

export type TrackingPingInsert = {
  organizationId: string;
  workerId: string;
  latitude: number;
  longitude: number;
  accuracy: number;
  timestamp: string;
};

export type WorkerLocationPingRecord = {
  id: string;
  organization_id: string;
  worker_profile_id: string;
  latitude: number;
  longitude: number;
  accuracy_meters: number | null;
  recorded_at: string;
  created_at: string;
};

export async function insertWorkerLocationPing(
  input: TrackingPingInsert,
): Promise<WorkerLocationPingRecord> {
  const { data, error } = await supabaseAdmin
    .from("worker_location_pings")
    .insert({
      organization_id: input.organizationId,
      worker_profile_id: input.workerId,
      latitude: input.latitude,
      longitude: input.longitude,
      accuracy_meters: input.accuracy,
      recorded_at: input.timestamp,
      source: "mobile_foreground",
    })
    .select(
      "id, organization_id, worker_profile_id, latitude, longitude, accuracy_meters, recorded_at, created_at",
    )
    .single<WorkerLocationPingRecord>();

  if (error) {
    handleSupabaseError(error, "Failed to store worker location ping.");
  }

  return data as WorkerLocationPingRecord;
}

export async function markWorkerActiveAndTouchLastSeen(
  workerId: string,
): Promise<void> {
  const { error } = await supabaseAdmin
    .from("profiles")
    .update({
      status: "active",
      last_seen_at: new Date().toISOString(),
    })
    .eq("id", workerId);

  if (error) {
    handleSupabaseError(error, "Failed to update worker activity.");
  }
}
