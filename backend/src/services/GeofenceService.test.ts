import test from "node:test";
import assert from "node:assert/strict";

import {
  GeofenceService,
  calculateDistanceMeters,
  type CheckGeofenceInput,
} from "./GeofenceService";

type InsertedEvent = {
  organizationId: string;
  workerId: string;
  jobId: string | null;
  locationId: string;
  eventType: "geofence_enter" | "geofence_exit";
  timestamp: string;
  latitude: number;
  longitude: number;
  accuracyMeters: number;
};

const baseInput: CheckGeofenceInput = {
  workerId: "worker-1",
  latitude: 53.5461,
  longitude: -113.4938,
  accuracy_meters: 10,
  timestamp: "2026-04-06T12:00:00.000Z",
};

test("calculateDistanceMeters returns zero for identical coordinates", () => {
  assert.equal(calculateDistanceMeters(53.5461, -113.4938, 53.5461, -113.4938), 0);
});

test("GeofenceService ignores low-quality pings above 50 meters accuracy", async () => {
  let assignmentFetches = 0;

  const service = new GeofenceService({
    async getActiveAssignedLocations() {
      assignmentFetches += 1;
      return [];
    },
    async getLastLocationEvent() {
      return null;
    },
    async insertLocationEvent() {
      throw new Error("Ignored pings must not create events.");
    },
  });

  const result = await service.checkGeofence({
    ...baseInput,
    accuracy_meters: 75,
  });

  assert.equal(result.ignored, true);
  assert.deepEqual(result.evaluations, []);
  assert.equal(assignmentFetches, 0);
});

test("GeofenceService initializes first state without creating an event", async () => {
  const insertedEvents: InsertedEvent[] = [];

  const service = new GeofenceService({
    async getActiveAssignedLocations() {
      return [
        {
          organizationId: "org-1",
          jobId: "job-1",
          locationId: "loc-1",
          latitude: 53.5461,
          longitude: -113.4938,
          geofenceRadiusMeters: 100,
        },
      ];
    },
    async getLastLocationEvent() {
      return null;
    },
    async insertLocationEvent(input) {
      insertedEvents.push(input);
    },
  });

  const result = await service.checkGeofence(baseInput);

  assert.equal(result.ignored, false);
  assert.equal(result.evaluations[0]?.state, "inside");
  assert.equal(result.evaluations[0]?.event_created, null);
  assert.deepEqual(insertedEvents, []);
});

test("GeofenceService creates an enter event when state changes from outside to inside", async () => {
  const insertedEvents: InsertedEvent[] = [];

  const service = new GeofenceService({
    async getActiveAssignedLocations() {
      return [
        {
          organizationId: "org-1",
          jobId: "job-1",
          locationId: "loc-1",
          latitude: 53.5461,
          longitude: -113.4938,
          geofenceRadiusMeters: 100,
        },
      ];
    },
    async getLastLocationEvent() {
      return {
        id: "evt-1",
        worker_profile_id: "worker-1",
        location_id: "loc-1",
        event_type: "geofence_exit",
        event_timestamp: "2026-04-06T11:00:00.000Z",
      };
    },
    async insertLocationEvent(input) {
      insertedEvents.push(input);
    },
  });

  const result = await service.checkGeofence(baseInput);

  assert.equal(result.evaluations[0]?.event_created, "geofence_enter");
  assert.equal(insertedEvents.length, 1);
  assert.equal(insertedEvents[0]?.eventType, "geofence_enter");
});

test("GeofenceService creates an exit event when state changes from inside to outside", async () => {
  const insertedEvents: InsertedEvent[] = [];

  const service = new GeofenceService({
    async getActiveAssignedLocations() {
      return [
        {
          organizationId: "org-1",
          jobId: "job-1",
          locationId: "loc-1",
          latitude: 53.5461,
          longitude: -113.4938,
          geofenceRadiusMeters: 50,
        },
      ];
    },
    async getLastLocationEvent() {
      return {
        id: "evt-1",
        worker_profile_id: "worker-1",
        location_id: "loc-1",
        event_type: "geofence_enter",
        event_timestamp: "2026-04-06T11:00:00.000Z",
      };
    },
    async insertLocationEvent(input) {
      insertedEvents.push(input);
    },
  });

  const result = await service.checkGeofence({
    ...baseInput,
    latitude: 53.56,
    longitude: -113.50,
  });

  assert.equal(result.evaluations[0]?.state, "outside");
  assert.equal(result.evaluations[0]?.event_created, "geofence_exit");
  assert.equal(insertedEvents[0]?.eventType, "geofence_exit");
});

test("GeofenceService does nothing when the worker state does not change", async () => {
  const insertedEvents: InsertedEvent[] = [];

  const service = new GeofenceService({
    async getActiveAssignedLocations() {
      return [
        {
          organizationId: "org-1",
          jobId: "job-1",
          locationId: "loc-1",
          latitude: 53.5461,
          longitude: -113.4938,
          geofenceRadiusMeters: 100,
        },
      ];
    },
    async getLastLocationEvent() {
      return {
        id: "evt-1",
        worker_profile_id: "worker-1",
        location_id: "loc-1",
        event_type: "geofence_enter",
        event_timestamp: "2026-04-06T11:00:00.000Z",
      };
    },
    async insertLocationEvent(input) {
      insertedEvents.push(input);
    },
  });

  const result = await service.checkGeofence(baseInput);

  assert.equal(result.evaluations[0]?.event_created, null);
  assert.deepEqual(insertedEvents, []);
});

test("GeofenceService evaluates multiple assigned locations independently", async () => {
  const insertedEvents: InsertedEvent[] = [];

  const service = new GeofenceService({
    async getActiveAssignedLocations() {
      return [
        {
          organizationId: "org-1",
          jobId: "job-1",
          locationId: "loc-1",
          latitude: 53.5461,
          longitude: -113.4938,
          geofenceRadiusMeters: 100,
        },
        {
          organizationId: "org-1",
          jobId: "job-2",
          locationId: "loc-2",
          latitude: 53.60,
          longitude: -113.60,
          geofenceRadiusMeters: 100,
        },
      ];
    },
    async getLastLocationEvent(_workerId, locationId) {
      if (locationId === "loc-1") {
        return {
          id: "evt-1",
          worker_profile_id: "worker-1",
          location_id: "loc-1",
          event_type: "geofence_exit",
          event_timestamp: "2026-04-06T11:00:00.000Z",
        };
      }

      return null;
    },
    async insertLocationEvent(input) {
      insertedEvents.push(input);
    },
  });

  const result = await service.checkGeofence(baseInput);

  assert.equal(result.evaluations.length, 2);
  assert.equal(result.evaluations[0]?.event_created, "geofence_enter");
  assert.equal(result.evaluations[1]?.event_created, null);
  assert.equal(insertedEvents.length, 1);
  assert.equal(insertedEvents[0]?.locationId, "loc-1");
});
