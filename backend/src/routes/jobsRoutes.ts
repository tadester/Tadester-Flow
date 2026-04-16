import { Router } from "express";

import {
  createJobController,
  getJobDetailsController,
  listJobsController,
  updateJobStatusController,
  workerJobActionController,
} from "../controllers/jobsController";
import { requireRole } from "../middleware/requireRole";
import { validateBody } from "../middleware/validate";
import {
  createJobSchema,
  jobStatusSchema,
  workerJobActionSchema,
} from "../schemas/jobSchemas";
import { asyncHandler } from "../utils/asyncHandler";

const router = Router();

router.post(
  "/",
  requireRole(["admin", "dispatcher", "operator"]),
  validateBody(createJobSchema),
  asyncHandler(createJobController),
);
router.get(
  "/",
  requireRole(["admin", "dispatcher", "operator", "field_worker"]),
  asyncHandler(listJobsController),
);
router.get(
  "/:id",
  requireRole(["admin", "dispatcher", "operator", "field_worker"]),
  asyncHandler(getJobDetailsController),
);
router.patch(
  "/:id/status",
  requireRole(["admin", "dispatcher", "operator"]),
  validateBody(jobStatusSchema),
  asyncHandler(updateJobStatusController),
);
router.post(
  "/:id/worker-action",
  requireRole(["field_worker"]),
  validateBody(workerJobActionSchema),
  asyncHandler(workerJobActionController),
);

export { router as jobsRouter };
