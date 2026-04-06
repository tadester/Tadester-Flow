import type { Request, Response } from "express";

import packageJson from "../../package.json";

export function healthHandler(_request: Request, response: Response) {
  response.status(200).json({
    status: "ok",
    timestamp: new Date().toISOString(),
    version: packageJson.version,
  });
}
