import type { Express } from "express";
import request from "supertest";

type TestWorker = {
  id: string;
  email: string;
  role: "field_worker";
  organizationId: string;
  status: "active" | "inactive";
  last_seen_at: string | null;
};

type StoredPing = {
  id: string;
  organization_id: string;
  worker_profile_id: string;
  latitude: number;
  longitude: number;
  accuracy_meters: number;
  recorded_at: string;
  created_at: string;
};

const authenticateTokenMock = jest.fn<Promise<TestWorker>, [string]>();
const insertWorkerLocationPingMock = jest.fn();
const markWorkerActiveAndTouchLastSeenMock = jest.fn();
const geofenceEvaluateMock = jest.fn();

jest.mock("../src/services/authService", () => ({
  authenticateToken: (token: string) => authenticateTokenMock(token),
}));

jest.mock("../src/repositories/trackingRepository", () => ({
  insertWorkerLocationPing: (input: unknown) => insertWorkerLocationPingMock(input),
  markWorkerActiveAndTouchLastSeen: (workerId: string) =>
    markWorkerActiveAndTouchLastSeenMock(workerId),
}));

jest.mock("../src/services/supabaseService", () => ({
  supabaseAdmin: {},
}));

jest.mock("../src/services/GeofenceService", () => ({
  GeofenceService: jest.fn().mockImplementation(() => ({
    evaluate: (input: unknown) => geofenceEvaluateMock(input),
    checkGeofence: (input: unknown) => geofenceEvaluateMock(input),
  })),
}));

describe("tracking ingestion pipeline", () => {
  let app: Express;
  let worker: TestWorker;
  let pingsTable: StoredPing[];

  beforeEach(async () => {
    jest.resetModules();

    process.env.PORT = "3000";
    process.env.SUPABASE_URL = "https://example.supabase.co";
    process.env.SUPABASE_SERVICE_ROLE_KEY = "service-role-key";

    worker = {
      id: "worker-1",
      email: "worker.one@tadesterops.dev",
      role: "field_worker",
      organizationId: "org-1",
      status: "inactive",
      last_seen_at: null,
    };
    pingsTable = [];

    authenticateTokenMock.mockResolvedValue(worker);
    insertWorkerLocationPingMock.mockImplementation(async (input) => {
      const record: StoredPing = {
        id: `ping-${pingsTable.length + 1}`,
        organization_id: input.organizationId as string,
        worker_profile_id: input.workerId as string,
        latitude: input.latitude as number,
        longitude: input.longitude as number,
        accuracy_meters: input.accuracy as number,
        recorded_at: input.timestamp as string,
        created_at: new Date().toISOString(),
      };

      pingsTable.push(record);
      return record;
    });
    markWorkerActiveAndTouchLastSeenMock.mockImplementation(async (workerId: string) => {
      if (workerId === worker.id) {
        worker.status = "active";
        worker.last_seen_at = new Date().toISOString();
      }
    });
    geofenceEvaluateMock.mockResolvedValue({
      worker_id: worker.id,
      ignored: false,
      evaluations: [],
    });

    const appModule = require("../src/app") as {
      createApp: () => Express;
    };
    app = appModule.createApp();
  });

  afterEach(() => {
    jest.clearAllMocks();
    pingsTable = [];
  });

  it("stores a worker ping, updates worker activity, and triggers geofence evaluation", async () => {
    const payload = {
      latitude: 53.5461,
      longitude: -113.4938,
      accuracy: 10,
      timestamp: new Date().toISOString(),
    };

    const response = await request(app)
      .post("/api/tracking/ping")
      .set("Authorization", "Bearer test-token")
      .send(payload);

    expect(response.status).toBe(200);
    expect(response.body).toEqual({ success: true });

    expect(pingsTable).toHaveLength(1);
    expect(pingsTable[0]).toMatchObject({
      worker_profile_id: worker.id,
      latitude: payload.latitude,
      longitude: payload.longitude,
      accuracy_meters: payload.accuracy,
      recorded_at: payload.timestamp,
    });

    await flushBackgroundTasks();

    expect(geofenceEvaluateMock).toHaveBeenCalledWith({
      workerId: worker.id,
      latitude: payload.latitude,
      longitude: payload.longitude,
      accuracy_meters: payload.accuracy,
      timestamp: payload.timestamp,
    });

    expect(worker.last_seen_at).not.toBeNull();
    expect(Date.now() - Date.parse(worker.last_seen_at ?? "")).toBeLessThan(5_000);
  });

  it("returns 400 for invalid payload values", async () => {
    const response = await request(app)
      .post("/api/tracking/ping")
      .set("Authorization", "Bearer test-token")
      .send({
        latitude: 120,
        longitude: -113.4938,
        accuracy: 10,
        timestamp: new Date().toISOString(),
      });

    expect(response.status).toBe(400);
    expect(response.body.error.message).toBe("Validation failed.");
    expect(insertWorkerLocationPingMock).not.toHaveBeenCalled();
  });

  it("returns 400 when required fields are missing", async () => {
    const response = await request(app)
      .post("/api/tracking/ping")
      .set("Authorization", "Bearer test-token")
      .send({
        latitude: 53.5461,
        timestamp: new Date().toISOString(),
      });

    expect(response.status).toBe(400);
    expect(response.body.error.message).toBe("Validation failed.");
    expect(response.body.error.details).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          path: "longitude",
        }),
      ]),
    );
  });

  it("returns 400 for malformed timestamps", async () => {
    const response = await request(app)
      .post("/api/tracking/ping")
      .set("Authorization", "Bearer test-token")
      .send({
        latitude: 53.5461,
        longitude: -113.4938,
        accuracy: 10,
        timestamp: "not-an-iso-date",
      });

    expect(response.status).toBe(400);
    expect(response.body.error.message).toBe("Validation failed.");
  });

  it("returns 401 when the request is unauthorized", async () => {
    const response = await request(app).post("/api/tracking/ping").send({
      latitude: 53.5461,
      longitude: -113.4938,
      accuracy: 10,
      timestamp: new Date().toISOString(),
    });

    expect(response.status).toBe(401);
    expect(response.body.error.code).toBe("UNAUTHORIZED");
    expect(insertWorkerLocationPingMock).not.toHaveBeenCalled();
  });

  it("handles multiple rapid pings without dropping inserts or geofence calls", async () => {
    const timestamps = Array.from({ length: 3 }, (_, index) =>
      new Date(Date.now() + index * 1000).toISOString(),
    );

    await Promise.all(
      timestamps.map((timestamp, index) =>
        request(app)
          .post("/api/tracking/ping")
          .set("Authorization", "Bearer test-token")
          .send({
            latitude: 53.5461 + index * 0.0001,
            longitude: -113.4938 - index * 0.0001,
            accuracy: 10,
            timestamp,
          }),
      ),
    );

    await flushBackgroundTasks();

    expect(pingsTable).toHaveLength(3);
    expect(geofenceEvaluateMock).toHaveBeenCalledTimes(3);
  });

  it("emits geofence enter and exit transitions without duplicates", async () => {
    const insertedEvents: Array<{ locationId: string; eventType: string }> = [];
    const lastEventByLocation = new Map<string, "geofence_enter" | "geofence_exit">();
    const { GeofenceService: RealGeofenceService } = jest.requireActual(
      "../src/services/GeofenceService",
    ) as typeof import("../src/services/GeofenceService");

    const dataProvider = {
      async getActiveAssignedLocations() {
        return [
          {
            organizationId: "org-1",
            jobId: "job-1",
            locationId: "location-1",
            latitude: 53.5463,
            longitude: -113.4937,
            geofenceRadiusMeters: 100,
          },
        ];
      },
      async getLastLocationEvent(_workerId: string, locationId: string) {
        const eventType = lastEventByLocation.get(locationId);

        if (!eventType) {
          return null;
        }

        return {
          id: `event-${locationId}`,
          worker_profile_id: worker.id,
          location_id: locationId,
          event_type: eventType,
          event_timestamp: new Date().toISOString(),
        };
      },
      async insertLocationEvent(input: {
        locationId: string;
        eventType: "geofence_enter" | "geofence_exit";
      }) {
        insertedEvents.push({
          locationId: input.locationId,
          eventType: input.eventType,
        });
        lastEventByLocation.set(input.locationId, input.eventType);
      },
    };

    const geofenceService = new RealGeofenceService(dataProvider);

    const outsideResult = await geofenceService.evaluate({
      workerId: worker.id,
      latitude: 53.5485,
      longitude: -113.4905,
      accuracy_meters: 10,
      timestamp: new Date().toISOString(),
    });

    expect(outsideResult.evaluations[0]?.event_created).toBeNull();
    expect(insertedEvents).toHaveLength(0);
    lastEventByLocation.set("location-1", "geofence_exit");

    const insideResult = await geofenceService.evaluate({
      workerId: worker.id,
      latitude: 53.54628,
      longitude: -113.49372,
      accuracy_meters: 10,
      timestamp: new Date().toISOString(),
    });

    expect(insideResult.evaluations[0]?.event_created).toBe("geofence_enter");
    expect(insertedEvents).toEqual([
      { locationId: "location-1", eventType: "geofence_enter" },
    ]);

    const repeatInsideResult = await geofenceService.evaluate({
      workerId: worker.id,
      latitude: 53.54629,
      longitude: -113.49371,
      accuracy_meters: 10,
      timestamp: new Date().toISOString(),
    });

    expect(repeatInsideResult.evaluations[0]?.event_created).toBeNull();
    expect(insertedEvents).toHaveLength(1);

    const exitResult = await geofenceService.evaluate({
      workerId: worker.id,
      latitude: 53.5485,
      longitude: -113.4905,
      accuracy_meters: 10,
      timestamp: new Date().toISOString(),
    });

    expect(exitResult.evaluations[0]?.event_created).toBe("geofence_exit");
    expect(insertedEvents).toEqual([
      { locationId: "location-1", eventType: "geofence_enter" },
      { locationId: "location-1", eventType: "geofence_exit" },
    ]);
  });
});

function flushBackgroundTasks(): Promise<void> {
  return new Promise((resolve) => setImmediate(resolve));
}
