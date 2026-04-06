import test from "node:test";
import assert from "node:assert/strict";

import type { Request, Response } from "express";

import { createJobSchema } from "../schemas/jobSchemas";
import { validateBody } from "./validate";

type JsonResponseBody = {
  error?: {
    message?: string;
    details?: Array<{
      path: string;
      message: string;
      code: string;
    }>;
  };
};

test("validateBody attaches parsed input to the request", () => {
  const middleware = validateBody(createJobSchema);
  const request = {
    body: {
      locationId: "11111111-1111-1111-1111-111111111111",
      title: "Route snow clearing",
      status: "scheduled",
      priority: "high",
      scheduledStartAt: "2026-04-06T10:00:00.000Z",
      scheduledEndAt: "2026-04-06T11:00:00.000Z",
    },
  } as Request;

  let nextCalled = false;

  middleware(
    request,
    {} as Response,
    () => {
      nextCalled = true;
    },
  );

  assert.equal(nextCalled, true);
  assert.equal(typeof request.validatedBody, "object");
});

test("validateBody returns structured 400 errors for invalid input", () => {
  const middleware = validateBody(createJobSchema);
  const request = {
    body: {
      title: "",
      status: "scheduled",
      priority: "high",
      scheduledStartAt: "bad-date",
      scheduledEndAt: "also-bad",
    },
  } as Request;

  let statusCode = 0;
  let responseBody: JsonResponseBody | undefined;

  const response = {
    status(code: number) {
      statusCode = code;
      return this;
    },
    json(payload: JsonResponseBody) {
      responseBody = payload;
      return this;
    },
  };

  middleware(request, response as Response, () => undefined);

  assert.equal(statusCode, 400);
  assert.equal(responseBody?.error?.message, "Validation failed.");
  assert.ok((responseBody?.error?.details?.length ?? 0) > 0);
});
