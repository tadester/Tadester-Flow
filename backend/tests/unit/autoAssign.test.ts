import { describe, expect, it } from "@jest/globals";

import { planAssignmentsByProximity } from "../../src/services/autoAssignmentService";

describe("planAssignmentsByProximity", () => {
  const jobs = [
    {
      id: "job-a",
      title: "North Yard",
      scheduledStartAt: "2026-04-07T09:00:00.000Z",
      location: {
        id: "loc-a",
        name: "North Yard",
        latitude: 53.5763,
        longitude: -113.6144,
      },
    },
    {
      id: "job-b",
      title: "Castle Downs",
      scheduledStartAt: "2026-04-07T10:00:00.000Z",
      location: {
        id: "loc-b",
        name: "Castle Downs",
        latitude: 53.6145,
        longitude: -113.5281,
      },
    },
  ];

  it("assigns jobs to the closest active workers", () => {
    const result = planAssignmentsByProximity(jobs, [
      {
        id: "worker-1",
        fullName: "Nearby North",
        email: "nearby@example.com",
        latitude: 53.5764,
        longitude: -113.6143,
        recordedAt: "2026-04-07T08:55:00.000Z",
        activeAssignmentsCount: 0,
      },
      {
        id: "worker-2",
        fullName: "Nearby Castle",
        email: "castle@example.com",
        latitude: 53.6144,
        longitude: -113.5282,
        recordedAt: "2026-04-07T08:56:00.000Z",
        activeAssignmentsCount: 0,
      },
    ]);

    expect(result.skippedJobs).toEqual([]);
    expect(result.assignments.map((item) => [item.jobId, item.workerProfileId])).toEqual([
      ["job-a", "worker-1"],
      ["job-b", "worker-2"],
    ]);
  });

  it("uses assignment load as a tie-breaker across multiple jobs", () => {
    const result = planAssignmentsByProximity(jobs, [
      {
        id: "worker-1",
        fullName: "Loaded Worker",
        email: "loaded@example.com",
        latitude: 53.5764,
        longitude: -113.6143,
        recordedAt: "2026-04-07T08:55:00.000Z",
        activeAssignmentsCount: 2,
      },
      {
        id: "worker-2",
        fullName: "Balanced Worker",
        email: "balanced@example.com",
        latitude: 53.5764,
        longitude: -113.6143,
        recordedAt: "2026-04-07T08:56:00.000Z",
        activeAssignmentsCount: 0,
      },
    ]);

    expect(result.assignments[0]?.workerProfileId).toBe("worker-2");
  });

  it("returns skipped jobs when no active workers are available", () => {
    const result = planAssignmentsByProximity(jobs, []);

    expect(result.assignments).toEqual([]);
    expect(result.skippedJobs).toHaveLength(2);
  });
});
