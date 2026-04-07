import { Router } from "express";

import { getWorkerStatusController } from "../controllers/workersController";
import { requireRole } from "../middleware/requireRole";
import { asyncHandler } from "../utils/asyncHandler";

const router = Router();

router.get(
  "/:id/status",
  requireRole(["admin", "dispatcher", "operator", "field_worker"]),
  asyncHandler(getWorkerStatusController),
);

export { router as workersRouter };
