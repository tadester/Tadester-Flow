import type { AuthenticatedUser } from "./domain/auth";

declare global {
  namespace Express {
    interface Request {
      user?: AuthenticatedUser;
      validatedBody?: unknown;
    }
  }
}

export {};
