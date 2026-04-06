import type { Request, Response } from "express";
import { Router } from "express";

import packageJson from "../../package.json";

const router = Router();

export function healthHandler(_request: Request, response: Response) {
  response.status(200).json({
    status: "ok",
    timestamp: new Date().toISOString(),
    version: packageJson.version,
  });
}

router.get("/", healthHandler);

export { router as healthRouter };
