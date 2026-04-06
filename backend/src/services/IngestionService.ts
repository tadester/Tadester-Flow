import type { TrackingPingInput } from "../schemas/trackingSchemas";
import { logger } from "../utils/logger";
import { enqueueBackgroundTask } from "../utils/backgroundTaskQueue";
import { handleSupabaseError } from "../utils/supabaseErrors";
import { updateProfileStatus } from "./profileService";
import { GeofenceService } from "./GeofenceService";
import { supabaseAdmin } from "./supabaseService";

type IngestionOptions = {
  organizationId: string;
  workerId: string;
  ping: TrackingPingInput;
};

type PingInsertRecord = {
  organization_id: string;
  worker_profile_id: string;
  latitude: number;
  longitude: number;
  accuracy_meters: number;
  recorded_at: string;
  source: "mobile_foreground";
};

type IngestionDependencies = {
  geofenceService?: Pick<GeofenceService, "checkGeofence">;
  pingWriter?: (record: PingInsertRecord) => Promise<void>;
  setWorkerStatus?: (workerId: string, status: "active" | "inactive") => Promise<void>;
};

export class IngestionService {
  private readonly geofenceService: Pick<GeofenceService, "checkGeofence">;
  private readonly pingWriter: (record: PingInsertRecord) => Promise<void>;
  private readonly setWorkerStatus: (
    workerId: string,
    status: "active" | "inactive",
  ) => Promise<void>;

  constructor(dependencies: IngestionDependencies = {}) {
    this.geofenceService = dependencies.geofenceService ?? new GeofenceService();
    this.pingWriter = dependencies.pingWriter ?? insertWorkerLocationPing;
    this.setWorkerStatus = dependencies.setWorkerStatus ?? updateProfileStatus;
  }

  async ingestPing(options: IngestionOptions): Promise<void> {
    await this.pingWriter({
      organization_id: options.organizationId,
      worker_profile_id: options.workerId,
      latitude: options.ping.latitude,
      longitude: options.ping.longitude,
      accuracy_meters: options.ping.accuracy_meters,
      recorded_at: options.ping.timestamp,
      source: "mobile_foreground",
    });

    await this.setWorkerStatus(options.workerId, "active");

    enqueueBackgroundTask("geofence_processing", async () => {
      try {
        await this.geofenceService.checkGeofence({
          workerId: options.workerId,
          latitude: options.ping.latitude,
          longitude: options.ping.longitude,
          accuracy_meters: options.ping.accuracy_meters,
          timestamp: options.ping.timestamp,
        });
      } catch (error) {
        const message =
          error instanceof Error ? error.message : "Unknown geofence processing failure.";
        logger.error(`geofence_processing failed: ${message}`);
      }
    });
  }
}

async function insertWorkerLocationPing(record: PingInsertRecord): Promise<void> {
  const { error } = await supabaseAdmin.from("worker_location_pings").insert(record);

  if (error) {
    handleSupabaseError(error, "Failed to store worker location ping.");
  }
}
