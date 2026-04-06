import test from "node:test";
import assert from "node:assert/strict";

import { createApp } from "./app";
import { healthHandler } from "./api/health";

type HealthPayload = {
  status: unknown;
  version: unknown;
  timestamp: unknown;
};

test("createApp returns an Express application instance", () => {
  const app = createApp();

  assert.equal(typeof app, "function");
  assert.equal(typeof app.listen, "function");
});

test("healthHandler returns the backend health payload", () => {
  let statusCode = 0;
  const payloads: HealthPayload[] = [];

  const response = {
    status(code: number) {
      statusCode = code;
      return this;
    },
    json(payload: HealthPayload) {
      payloads.push(payload);
      return this;
    },
  };

  healthHandler({} as never, response as never);

  assert.equal(statusCode, 200);
  if (payloads.length === 0) {
    throw new Error("Expected healthHandler to write a JSON payload.");
  }

  const payload = payloads[0];
  assert.equal(payload.status, "ok");
  assert.equal(payload.version, "0.1.0");
  assert.ok(Date.parse(String(payload.timestamp)));
});
