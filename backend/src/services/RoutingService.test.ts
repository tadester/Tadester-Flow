import test from "node:test";
import assert from "node:assert/strict";

import {
  RoutingService,
  type DailyRouteResult,
  type OrderedRouteJob,
} from "./RoutingService";

type MockJob = {
  id: string;
  title: string;
  status: string;
  priority: string;
  scheduled_start_at: string;
  scheduled_end_at: string;
  location: {
    id: string;
    name: string;
    lat: number;
    lng: number;
  };
};

type MockDistanceMatrixRequest = {
  params: {
    origins: string[];
    destinations: string[];
    mode: string;
    key: string;
  };
};

function createMockJobs(): MockJob[] {
  return [
    {
      id: "job-2",
      title: "Second stop",
      status: "scheduled",
      priority: "medium",
      scheduled_start_at: "2026-04-06T11:00:00.000Z",
      scheduled_end_at: "2026-04-06T12:00:00.000Z",
      location: {
        id: "loc-2",
        name: "Site Two",
        lat: 53.5444,
        lng: -113.4909,
      },
    },
    {
      id: "job-1",
      title: "First stop",
      status: "scheduled",
      priority: "high",
      scheduled_start_at: "2026-04-06T09:00:00.000Z",
      scheduled_end_at: "2026-04-06T10:00:00.000Z",
      location: {
        id: "loc-1",
        name: "Site One",
        lat: 53.5461,
        lng: -113.4938,
      },
    },
  ];
}

test("RoutingService returns sorted jobs when the Google Maps key is missing", async () => {
  const service = new RoutingService({
    dataProvider: {
      async getAssignedJobsForDate() {
        return createMockJobs();
      },
      async getLastKnownLocation() {
        return null;
      },
    },
    mapsClient: {
      async distancematrix() {
        throw new Error("The matrix client should not be called without an API key.");
      },
    },
    apiKey: "",
  });

  const result = await service.getDailyRoute("worker-1", "2026-04-06");

  assert.deepEqual(result, {
    ordered_jobs: [
      {
        id: "job-1",
        title: "First stop",
        status: "scheduled",
        priority: "high",
        scheduled_start_at: "2026-04-06T09:00:00.000Z",
        scheduled_end_at: "2026-04-06T10:00:00.000Z",
        location: {
          id: "loc-1",
          name: "Site One",
          lat: 53.5461,
          lng: -113.4938,
        },
      },
      {
        id: "job-2",
        title: "Second stop",
        status: "scheduled",
        priority: "medium",
        scheduled_start_at: "2026-04-06T11:00:00.000Z",
        scheduled_end_at: "2026-04-06T12:00:00.000Z",
        location: {
          id: "loc-2",
          name: "Site Two",
          lat: 53.5444,
          lng: -113.4909,
        },
      },
    ],
    legs: [],
    total_distance: 0,
    total_time: 0,
  } satisfies DailyRouteResult);
});

test("RoutingService builds route legs from the worker's last known location using driving mode", async () => {
  const requests: MockDistanceMatrixRequest[] = [];

  const service = new RoutingService({
    dataProvider: {
      async getAssignedJobsForDate() {
        return createMockJobs();
      },
      async getLastKnownLocation() {
        return {
          lat: 53.55,
          lng: -113.5,
          recordedAt: "2026-04-06T08:45:00.000Z",
        };
      },
    },
    mapsClient: {
      async distancematrix(request) {
        requests.push(request as MockDistanceMatrixRequest);

        return {
          data: {
            rows: [
              {
                elements: [
                  {
                    status: "OK",
                    distance: { value: 1200 },
                    duration: { value: 300 },
                  },
                  {
                    status: "OK",
                    distance: { value: 99999 },
                    duration: { value: 99999 },
                  },
                ],
              },
              {
                elements: [
                  {
                    status: "OK",
                    distance: { value: 99999 },
                    duration: { value: 99999 },
                  },
                  {
                    status: "OK",
                    distance: { value: 2600 },
                    duration: { value: 540 },
                  },
                ],
              },
            ],
          },
        };
      },
    },
    apiKey: "maps-key",
    now: () => new Date("2026-04-06T08:30:00.000Z"),
  });

  const result = await service.getDailyRoute("worker-1", "2026-04-06");

  assert.equal(requests.length, 1);
  assert.equal(requests[0].params.mode, "driving");
  assert.deepEqual(requests[0].params.origins, ["53.55,-113.5", "53.5461,-113.4938"]);
  assert.deepEqual(requests[0].params.destinations, [
    "53.5461,-113.4938",
    "53.5444,-113.4909",
  ]);

  assert.deepEqual(result.ordered_jobs.map((job: OrderedRouteJob) => job.id), [
    "job-1",
    "job-2",
  ]);
  assert.equal(result.total_distance, 3800);
  assert.equal(result.total_time, 840);
  assert.equal(result.legs[0]?.from_job_id, null);
  assert.equal(result.legs[0]?.to_job_id, "job-1");
  assert.equal(result.legs[1]?.from_job_id, "job-1");
  assert.equal(result.legs[1]?.to_job_id, "job-2");
  assert.equal(result.legs[0]?.estimated_arrival, "2026-04-06T08:35:00.000Z");
  assert.equal(result.legs[1]?.estimated_arrival, "2026-04-06T08:44:00.000Z");
});

test("RoutingService falls back to sorted jobs when the Distance Matrix API fails", async () => {
  const service = new RoutingService({
    dataProvider: {
      async getAssignedJobsForDate() {
        return createMockJobs();
      },
      async getLastKnownLocation() {
        return {
          lat: 53.55,
          lng: -113.5,
          recordedAt: "2026-04-06T08:45:00.000Z",
        };
      },
    },
    mapsClient: {
      async distancematrix() {
        throw new Error("Google Maps unavailable");
      },
    },
    apiKey: "maps-key",
  });

  const result = await service.getDailyRoute("worker-1", "2026-04-06");

  assert.deepEqual(result, {
    ordered_jobs: [
      {
        id: "job-1",
        title: "First stop",
        status: "scheduled",
        priority: "high",
        scheduled_start_at: "2026-04-06T09:00:00.000Z",
        scheduled_end_at: "2026-04-06T10:00:00.000Z",
        location: {
          id: "loc-1",
          name: "Site One",
          lat: 53.5461,
          lng: -113.4938,
        },
      },
      {
        id: "job-2",
        title: "Second stop",
        status: "scheduled",
        priority: "medium",
        scheduled_start_at: "2026-04-06T11:00:00.000Z",
        scheduled_end_at: "2026-04-06T12:00:00.000Z",
        location: {
          id: "loc-2",
          name: "Site Two",
          lat: 53.5444,
          lng: -113.4909,
        },
      },
    ],
    legs: [],
    total_distance: 0,
    total_time: 0,
  } satisfies DailyRouteResult);
});
