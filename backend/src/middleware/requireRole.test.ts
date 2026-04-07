import test from "node:test";
import assert from "node:assert/strict";

import type { NextFunction, Request, Response } from "express";

import { requireRole } from "./requireRole";

test("requireRole allows an authorized role", () => {
  const middleware = requireRole(["admin", "dispatcher"]);
  const request = {
    user: {
      id: "11111111-1111-1111-1111-111111111111",
      email: "dispatcher@tadesterops.dev",
      role: "dispatcher",
      organizationId: "22222222-2222-2222-2222-222222222222",
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
});

test("requireRole rejects an unauthorized role", () => {
  const middleware = requireRole(["admin", "dispatcher"]);
  const request = {
    user: {
      id: "11111111-1111-1111-1111-111111111111",
      email: "worker@tadesterops.dev",
      role: "field_worker",
      organizationId: "22222222-2222-2222-2222-222222222222",
    },
  } as Request;

  let forwardedError: unknown;

  middleware(
    request,
    {} as Response,
    ((error?: unknown) => {
      forwardedError = error;
    }) as NextFunction,
  );

  assert.ok(forwardedError instanceof Error);
  assert.equal((forwardedError as Error).message, "You do not have permission to perform this action.");
});
