import type { TrackingPingInput } from "../schemas/trackingSchemas";
import { logger } from "../utils/logger";
import { enqueueBackgroundTask } from "../utils/backgroundTaskQueue";
import { GeofenceService } from "./GeofenceService";
import {
  insertWorkerLocationPing,
  markWorkerActiveAndTouchLastSeen,
  type TrackingPingInsert,
  type WorkerLocationPingRecord,
} from "../repositories/trackingRepository";

type IngestionOptions = {
  organizationId: string;
  workerId: string;
  ping: TrackingPingInput;
};

type IngestionDependencies = {
  geofenceService?: Pick<GeofenceService, "evaluate">;
  pingWriter?: (record: TrackingPingInsert) => Promise<WorkerLocationPingRecord>;
  markWorkerActive?: (workerId: string) => Promise<void>;
};

export class IngestionService {
  private readonly geofenceService: Pick<GeofenceService, "evaluate">;
  private readonly pingWriter: (
    record: TrackingPingInsert,
  ) => Promise<WorkerLocationPingRecord>;
  private readonly markWorkerActive: (workerId: string) => Promise<void>;

  constructor(dependencies: IngestionDependencies = {}) {
    this.geofenceService = dependencies.geofenceService ?? new GeofenceService();
    this.pingWriter = dependencies.pingWriter ?? insertWorkerLocationPing;
    this.markWorkerActive =
      dependencies.markWorkerActive ?? markWorkerActiveAndTouchLastSeen;
  }

  async ingestPing(options: IngestionOptions): Promise<void> {
    await this.pingWriter({
      organizationId: options.organizationId,
      workerId: options.workerId,
      latitude: options.ping.latitude,
      longitude: options.ping.longitude,
      accuracy: options.ping.accuracy,
      timestamp: options.ping.timestamp,
    });

    await this.markWorkerActive(options.workerId);

    enqueueBackgroundTask("geofence_processing", async () => {
      try {
        await this.geofenceService.evaluate({
          workerId: options.workerId,
          latitude: options.ping.latitude,
          longitude: options.ping.longitude,
          accuracy_meters: options.ping.accuracy,
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
