import { Router } from "express";

import {
  createJobController,
  getJobDetailsController,
  listJobsController,
  updateJobStatusController,
} from "../controllers/jobsController";
import { requireRole } from "../middleware/requireRole";
import { validateBody } from "../middleware/validate";
import { createJobSchema, jobStatusSchema } from "../schemas/jobSchemas";
import { asyncHandler } from "../utils/asyncHandler";

const router = Router();

router.post(
  "/",
  requireRole(["admin", "dispatcher", "operator"]),
  validateBody(createJobSchema),
  asyncHandler(createJobController),
);
router.get("/", asyncHandler(listJobsController));
router.get("/:id", asyncHandler(getJobDetailsController));
router.patch(
  "/:id/status",
  requireRole(["admin", "dispatcher", "operator"]),
  validateBody(jobStatusSchema),
  asyncHandler(updateJobStatusController),
);

export { router as jobsRouter };
