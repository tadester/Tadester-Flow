import test from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { createRequire } from "node:module";
import type { Express } from "express";

import { healthHandler } from "./controllers/healthController";

const requireModule = createRequire(__filename);

function loadAppModule() {
  const modulePath = path.resolve(process.cwd(), "dist/app.js");
  const resolvedModulePath = requireModule.resolve(modulePath);
  delete requireModule.cache[resolvedModulePath];
  return requireModule(modulePath) as {
    createApp: () => Express;
  };
}

function withBackendEnv<T>(callback: () => T): T {
  const originalPort = process.env.PORT;
  const originalSupabaseUrl = process.env.SUPABASE_URL;
  const originalServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  process.env.PORT = "3000";
  process.env.SUPABASE_URL = "https://example.supabase.co";
  process.env.SUPABASE_SERVICE_ROLE_KEY = "service-role-key";

  try {
    return callback();
  } finally {
    process.env.PORT = originalPort;
    process.env.SUPABASE_URL = originalSupabaseUrl;
    process.env.SUPABASE_SERVICE_ROLE_KEY = originalServiceRoleKey;
  }
}

type HealthPayload = {
  status: unknown;
  version: unknown;
  timestamp: unknown;
};

test("createApp returns an Express application instance", () => {
  const { createApp } = withBackendEnv(loadAppModule);
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
