import test from "node:test";
import assert from "node:assert/strict";

import { StaleWorkerService } from "./StaleWorkerService";

test("StaleWorkerService marks workers inactive when the last ping is older than ten minutes", async () => {
  const statusUpdates: Array<{ workerId: string; status: "active" | "inactive" }> = [];

  const service = new StaleWorkerService({
    async listActiveWorkers() {
      return [
        { id: "worker-1", status: "active" },
        { id: "worker-2", status: "active" },
      ];
    },
    async listRecentPings() {
      return [
        {
          worker_profile_id: "worker-1",
          recorded_at: "2026-04-06T11:40:00.000Z",
        },
        {
          worker_profile_id: "worker-2",
          recorded_at: "2026-04-06T11:55:30.000Z",
        },
      ];
    },
    async setWorkerStatus(workerId, status) {
      statusUpdates.push({ workerId, status });
    },
    now: () => new Date("2026-04-06T12:00:00.000Z"),
  });

  const staleWorkerIds = await service.markInactiveWorkers();

  assert.deepEqual(staleWorkerIds, ["worker-1"]);
  assert.deepEqual(statusUpdates, [{ workerId: "worker-1", status: "inactive" }]);
});

test("StaleWorkerService skips workers with no pings", async () => {
  const statusUpdates: Array<{ workerId: string; status: "active" | "inactive" }> = [];

  const service = new StaleWorkerService({
    async listActiveWorkers() {
      return [{ id: "worker-1", status: "active" }];
    },
    async listRecentPings() {
      return [];
    },
    async setWorkerStatus(workerId, status) {
      statusUpdates.push({ workerId, status });
    },
    now: () => new Date("2026-04-06T12:00:00.000Z"),
  });

  const staleWorkerIds = await service.markInactiveWorkers();

  assert.deepEqual(staleWorkerIds, []);
  assert.deepEqual(statusUpdates, []);
});
