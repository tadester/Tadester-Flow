import type { NextFunction, Request, Response } from "express";

import { authenticateToken } from "../services/authService";
import { UnauthorizedError } from "../utils/errors";

export function requireAuth(
  request: Request,
  _response: Response,
  next: NextFunction,
) {
  const authorizationHeader = request.headers.authorization;

  if (!authorizationHeader) {
    next(new UnauthorizedError("Missing Authorization header."));
    return;
  }

  const [scheme, token] = authorizationHeader.split(" ");

  if (scheme !== "Bearer" || !token) {
    next(new UnauthorizedError("Authorization header must use Bearer token."));
    return;
  }

  authenticateToken(token)
    .then((user) => {
      request.user = user;
      next();
    })
    .catch(next);
}
