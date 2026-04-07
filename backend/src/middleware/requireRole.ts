import type { NextFunction, Request, Response } from "express";

import type { AppRole } from "../domain/auth";
import { ForbiddenError, UnauthorizedError } from "../utils/errors";

export function requireRole(roles: AppRole[]) {
  return (
    request: Request,
    _response: Response,
    next: NextFunction,
  ) => {
    if (!request.user) {
      next(new UnauthorizedError("Authentication is required."));
      return;
    }

    if (!roles.includes(request.user.role)) {
      next(new ForbiddenError("You do not have permission to perform this action."));
      return;
    }

    next();
  };
}
