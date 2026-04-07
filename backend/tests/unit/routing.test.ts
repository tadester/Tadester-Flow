jest.mock("../../src/services/supabaseService", () => ({
  supabaseAdmin: {},
}));

import {
  sortRoutingJobsForDailyRoute,
  type RoutingJobRecord,
} from "../../src/services/RoutingService";

function createJob(
  overrides: Partial<RoutingJobRecord> & Pick<RoutingJobRecord, "id">,
): RoutingJobRecord {
  return {
    id: overrides.id,
    title: overrides.title ?? `Job ${overrides.id}`,
    status: overrides.status ?? "scheduled",
    priority: overrides.priority ?? "medium",
    scheduled_start_at:
      overrides.scheduled_start_at ?? "2026-04-06T09:00:00.000Z",
    scheduled_end_at: overrides.scheduled_end_at ?? "2026-04-06T10:00:00.000Z",
    location: overrides.location ?? {
      id: `location-${overrides.id}`,
      name: `Location ${overrides.id}`,
      lat: 53.5461,
      lng: -113.4938,
    },
  };
}

describe("daily route ordering logic", () => {
  it("should return an empty array safely for an empty job list", () => {
    expect(sortRoutingJobsForDailyRoute([])).toEqual([]);
  });

  it("should return a single job unchanged", () => {
    const singleJob = [createJob({ id: "job-1" })];

    expect(sortRoutingJobsForDailyRoute(singleJob)).toEqual(singleJob);
  });

  it("should sort jobs by scheduled time ascending", () => {
    const jobs = [
      createJob({ id: "job-3", scheduled_start_at: "2026-04-06T12:00:00.000Z" }),
      createJob({ id: "job-1", scheduled_start_at: "2026-04-06T08:00:00.000Z" }),
      createJob({ id: "job-2", scheduled_start_at: "2026-04-06T10:00:00.000Z" }),
    ];

    const orderedIds = sortRoutingJobsForDailyRoute(jobs).map((job) => job.id);

    expect(orderedIds).toEqual(["job-1", "job-2", "job-3"]);
  });

  it("should use a deterministic id fallback when scheduled times are identical", () => {
    const jobs = [
      createJob({ id: "job-b", scheduled_start_at: "2026-04-06T09:00:00.000Z" }),
      createJob({ id: "job-a", scheduled_start_at: "2026-04-06T09:00:00.000Z" }),
      createJob({ id: "job-c", scheduled_start_at: "2026-04-06T09:00:00.000Z" }),
    ];

    const orderedIds = sortRoutingJobsForDailyRoute(jobs).map((job) => job.id);

    expect(orderedIds).toEqual(["job-a", "job-b", "job-c"]);
  });

  it("should place malformed or missing scheduled times after valid scheduled jobs", () => {
    const jobs = [
      createJob({ id: "job-2", scheduled_start_at: "" }),
      createJob({ id: "job-3", scheduled_start_at: "not-a-date" }),
      createJob({ id: "job-1", scheduled_start_at: "2026-04-06T08:30:00.000Z" }),
    ];

    const orderedIds = sortRoutingJobsForDailyRoute(jobs).map((job) => job.id);

    expect(orderedIds).toEqual(["job-1", "job-2", "job-3"]);
  });

  it("should not crash when multiple malformed jobs are present", () => {
    const jobs = [
      createJob({ id: "job-z", scheduled_start_at: "bad-input" }),
      createJob({ id: "job-a", scheduled_start_at: "" }),
      createJob({ id: "job-m", scheduled_start_at: "still-bad" }),
    ];

    expect(() => sortRoutingJobsForDailyRoute(jobs)).not.toThrow();
    expect(sortRoutingJobsForDailyRoute(jobs).map((job) => job.id)).toEqual([
      "job-a",
      "job-m",
      "job-z",
    ]);
  });
});
