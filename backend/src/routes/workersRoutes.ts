import { Router } from "express";

import {
  getCurrentWorkerRouteController,
  getWorkerRouteController,
  getWorkerStatusController,
} from "../controllers/workersController";
import { requireRole } from "../middleware/requireRole";
import { asyncHandler } from "../utils/asyncHandler";

const router = Router();

router.get(
  "/me/route",
  requireRole(["admin", "dispatcher", "operator", "field_worker"]),
  asyncHandler(getCurrentWorkerRouteController),
);
router.get(
  "/:id/route",
  requireRole(["admin", "dispatcher", "operator", "field_worker"]),
  asyncHandler(getWorkerRouteController),
);
router.get(
  "/:id/status",
  requireRole(["admin", "dispatcher", "operator", "field_worker"]),
  asyncHandler(getWorkerStatusController),
);

export { router as workersRouter };
