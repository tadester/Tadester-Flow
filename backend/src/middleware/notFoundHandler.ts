import type { NextFunction, Request, Response } from "express";

export function notFoundHandler(
  request: Request,
  response: Response,
  _next: NextFunction,
) {
  response.status(404).json({
    error: {
      message: `Route not found: ${request.method} ${request.originalUrl}`,
      code: "ROUTE_NOT_FOUND",
    },
  });
}
