import { logger } from "../utils/logger";
import { handleSupabaseError } from "../utils/supabaseErrors";
import { updateProfileStatus } from "./profileService";
import { supabaseAdmin } from "./supabaseService";

const STALE_PING_THRESHOLD_MS = 10 * 60 * 1000;
export const STALE_WORKER_INTERVAL_MS = 5 * 60 * 1000;

type WorkerProfile = {
  id: string;
  status: "active" | "inactive";
};

type WorkerPing = {
  worker_profile_id: string;
  recorded_at: string;
};

type StaleWorkerDependencies = {
  listActiveWorkers?: () => Promise<WorkerProfile[]>;
  listRecentPings?: (workerIds: string[]) => Promise<WorkerPing[]>;
  setWorkerStatus?: (workerId: string, status: "active" | "inactive") => Promise<void>;
  now?: () => Date;
};

export class StaleWorkerService {
  private readonly listActiveWorkers: () => Promise<WorkerProfile[]>;
  private readonly listRecentPings: (workerIds: string[]) => Promise<WorkerPing[]>;
  private readonly setWorkerStatus: (
    workerId: string,
    status: "active" | "inactive",
  ) => Promise<void>;
  private readonly now: () => Date;

  constructor(dependencies: StaleWorkerDependencies = {}) {
    this.listActiveWorkers = dependencies.listActiveWorkers ?? fetchActiveFieldWorkers;
    this.listRecentPings = dependencies.listRecentPings ?? fetchWorkerPings;
    this.setWorkerStatus = dependencies.setWorkerStatus ?? updateProfileStatus;
    this.now = dependencies.now ?? (() => new Date());
  }

  async markInactiveWorkers(): Promise<string[]> {
    const activeWorkers = await this.listActiveWorkers();

    if (activeWorkers.length === 0) {
      return [];
    }

    const pings = await this.listRecentPings(activeWorkers.map((worker) => worker.id));
    const latestPingByWorker = new Map<string, string>();

    for (const ping of pings) {
      if (!latestPingByWorker.has(ping.worker_profile_id)) {
        latestPingByWorker.set(ping.worker_profile_id, ping.recorded_at);
      }
    }

    const nowMs = this.now().getTime();
    const staleWorkerIds = activeWorkers
      .filter((worker) => {
        const latestPingTimestamp = latestPingByWorker.get(worker.id);

        if (!latestPingTimestamp) {
          return false;
        }

        const latestPingMs = Date.parse(latestPingTimestamp);

        return (
          !Number.isNaN(latestPingMs) &&
          nowMs - latestPingMs > STALE_PING_THRESHOLD_MS
        );
      })
      .map((worker) => worker.id);

    await Promise.all(
      staleWorkerIds.map((workerId) => this.setWorkerStatus(workerId, "inactive")),
    );

    return staleWorkerIds;
  }
}

export function startStaleWorkerScheduler(
  staleWorkerService: StaleWorkerService = new StaleWorkerService(),
): NodeJS.Timeout {
  const interval = setInterval(() => {
    staleWorkerService
      .markInactiveWorkers()
      .then((workerIds) => {
        if (workerIds.length > 0) {
          logger.info(`Marked ${workerIds.length} workers inactive.`);
        }
      })
      .catch((error: unknown) => {
        const message =
          error instanceof Error ? error.message : "Unknown stale worker scheduler failure.";
        logger.error(`stale_worker_scheduler failed: ${message}`);
      });
  }, STALE_WORKER_INTERVAL_MS);

  interval.unref();

  return interval;
}

async function fetchActiveFieldWorkers(): Promise<WorkerProfile[]> {
  const { data, error } = await supabaseAdmin
    .from("profiles")
    .select("id, status")
    .eq("role", "field_worker")
    .eq("status", "active");

  if (error) {
    handleSupabaseError(error, "Failed to fetch active workers.");
  }

  return (data ?? []) as WorkerProfile[];
}

async function fetchWorkerPings(workerIds: string[]): Promise<WorkerPing[]> {
  if (workerIds.length === 0) {
    return [];
  }

  const { data, error } = await supabaseAdmin
    .from("worker_location_pings")
    .select("worker_profile_id, recorded_at")
    .in("worker_profile_id", workerIds)
    .order("recorded_at", { ascending: false });

  if (error) {
    handleSupabaseError(error, "Failed to fetch worker pings.");
  }

  return (data ?? []) as WorkerPing[];
}
