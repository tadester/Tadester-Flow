import test from "node:test";
import assert from "node:assert/strict";

import { IngestionService } from "./IngestionService";

test("IngestionService stores the ping and marks the worker active", async () => {
  const pingWrites: unknown[] = [];
  const activeWorkers: string[] = [];
  let geofenceCalls = 0;

  const service = new IngestionService({
    async pingWriter(record) {
      pingWrites.push(record);
      return {
        id: "ping-1",
        organization_id: "org-1",
        worker_profile_id: "worker-1",
        latitude: 53.5461,
        longitude: -113.4938,
        accuracy_meters: 8,
        recorded_at: "2026-04-06T12:00:00.000Z",
        created_at: "2026-04-06T12:00:00.000Z",
      };
    },
    async markWorkerActive(workerId) {
      activeWorkers.push(workerId);
    },
    geofenceService: {
      async evaluate() {
        geofenceCalls += 1;
        return {
          worker_id: "worker-1",
          ignored: false,
          evaluations: [],
        };
      },
    },
  });

  await service.ingestPing({
    organizationId: "org-1",
    workerId: "worker-1",
      ping: {
        latitude: 53.5461,
        longitude: -113.4938,
        accuracy: 8,
        timestamp: "2026-04-06T12:00:00.000Z",
      },
    });

  assert.equal(pingWrites.length, 1);
  assert.deepEqual(activeWorkers, ["worker-1"]);

  await new Promise((resolve) => setImmediate(resolve));

  assert.equal(geofenceCalls, 1);
});
