import { Router } from "express";

import {
  createLocationController,
  listLocationsController,
} from "../controllers/locationsController";
import { requireRole } from "../middleware/requireRole";
import { validateBody } from "../middleware/validate";
import { createLocationSchema } from "../schemas/locationSchemas";
import { asyncHandler } from "../utils/asyncHandler";

const router = Router();

router.post(
  "/",
  requireRole(["admin", "dispatcher", "operator"]),
  validateBody(createLocationSchema),
  asyncHandler(createLocationController),
);
router.get(
  "/",
  requireRole(["admin", "dispatcher", "operator", "field_worker"]),
  asyncHandler(listLocationsController),
);

export { router as locationsRouter };
