import type { NextFunction, Request, Response } from "express";
import type { ZodType, ZodTypeDef } from "zod";
import { ZodError } from "zod";

export function validateBody<T>(schema: ZodType<T, ZodTypeDef, unknown>) {
  return (
    request: Request,
    response: Response,
    next: NextFunction,
  ) => {
    try {
      request.validatedBody = schema.parse(request.body);
      next();
    } catch (error) {
      if (error instanceof ZodError) {
        response.status(400).json({
          error: {
            message: "Validation failed.",
            details: error.issues.map((issue) => ({
              path: issue.path.join("."),
              message: issue.message,
              code: issue.code,
            })),
          },
        });
        return;
      }

      next(error);
    }
  };
}
