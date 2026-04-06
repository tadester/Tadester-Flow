import test from "node:test";
import assert from "node:assert/strict";

import { createJobSchema } from "./jobSchemas";

test("createJobSchema accepts a valid job payload", () => {
  const parsed = createJobSchema.parse({
    locationId: "11111111-1111-1111-1111-111111111111",
    title: "Snow clearing",
    description: "Morning pass",
    status: "scheduled",
    priority: "high",
    scheduledStartAt: "2026-04-06T10:00:00.000Z",
    scheduledEndAt: "2026-04-06T12:00:00.000Z",
  });

  assert.equal(parsed.title, "Snow clearing");
  assert.equal(parsed.priority, "high");
});

test("createJobSchema rejects an invalid payload", () => {
  assert.throws(
    () =>
      createJobSchema.parse({
        locationId: "not-a-uuid",
        title: "",
        status: "scheduled",
        priority: "high",
        scheduledStartAt: "bad-date",
        scheduledEndAt: "also-bad",
      }),
    /Invalid/,
  );
});
