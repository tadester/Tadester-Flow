import type { Request } from "express";

import type { AuthenticatedUser } from "../domain/auth";
import { BadRequestError, UnauthorizedError } from "./errors";

export function getAuthenticatedUser(request: Request): AuthenticatedUser {
  if (!request.user) {
    throw new UnauthorizedError("Authentication is required.");
  }

  return request.user;
}

export function getValidatedBody<T>(request: Request): T {
  if (typeof request.validatedBody === "undefined") {
    throw new BadRequestError("Validated request body is missing.");
  }

  return request.validatedBody as T;
}

export function getParamValue(
  value: string | string[] | undefined,
  paramName: string,
): string {
  if (typeof value !== "string" || value.length === 0) {
    throw new BadRequestError(`Missing or invalid ${paramName} parameter.`);
  }

  return value;
}
