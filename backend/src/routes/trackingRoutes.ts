import { Router } from "express";

import { trackingPingController } from "../controllers/TrackingController";
import { requireRole } from "../middleware/requireRole";
import { validateBody } from "../middleware/validate";
import { trackingPingSchema } from "../schemas/trackingSchemas";
import { asyncHandler } from "../utils/asyncHandler";

const router = Router();

router.post(
  "/ping",
  requireRole(["field_worker"]),
  validateBody(trackingPingSchema),
  asyncHandler(trackingPingController),
);

export { router as trackingRouter };
