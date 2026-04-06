import { Router } from "express";

import packageJson from "../../package.json";

const router = Router();

router.get("/", (_request, response) => {
  response.status(200).json({
    status: "ok",
    timestamp: new Date().toISOString(),
    version: packageJson.version,
  });
});

export { router as healthRouter };
