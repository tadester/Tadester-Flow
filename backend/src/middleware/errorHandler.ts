import type { NextFunction, Request, Response } from "express";

import { logger } from "../utils/logger";
import { AppError } from "../utils/errors";

export function errorHandler(
  error: unknown,
  _request: Request,
  response: Response,
  _next: NextFunction,
) {
  if (error instanceof AppError) {
    response.status(error.statusCode).json({
      error: {
        message: error.message,
        code: error.code,
      },
    });
    return;
  }

  logger.error(error instanceof Error ? error.message : "Unexpected server error");

  response.status(500).json({
    error: {
      message: "Internal server error.",
      code: "INTERNAL_SERVER_ERROR",
    },
  });
}
