import test from "node:test";
import assert from "node:assert/strict";

import { createAssignmentSchema } from "./assignmentSchemas";

test("createAssignmentSchema applies the default assignment status", () => {
  const parsed = createAssignmentSchema.parse({
    jobId: "11111111-1111-1111-1111-111111111111",
    workerProfileId: "22222222-2222-2222-2222-222222222222",
  });

  assert.equal(parsed.assignmentStatus, "assigned");
});

test("createAssignmentSchema rejects invalid ids", () => {
  assert.throws(
    () =>
      createAssignmentSchema.parse({
        jobId: "invalid",
        workerProfileId: "also-invalid",
      }),
    /Invalid uuid/,
  );
});
