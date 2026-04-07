import { Router } from "express";

import {
  autoAssignJobsController,
  createAssignmentController,
} from "../controllers/assignmentsController";
import { requireRole } from "../middleware/requireRole";
import { validateBody } from "../middleware/validate";
import { createAssignmentSchema } from "../schemas/assignmentSchemas";
import { autoAssignJobsSchema } from "../schemas/autoAssignmentSchemas";
import { asyncHandler } from "../utils/asyncHandler";

const router = Router();

router.post(
  "/auto",
  requireRole(["admin", "dispatcher", "operator"]),
  validateBody(autoAssignJobsSchema),
  asyncHandler(autoAssignJobsController),
);

router.post(
  "/",
  requireRole(["admin", "dispatcher", "operator"]),
  validateBody(createAssignmentSchema),
  asyncHandler(createAssignmentController),
);

export { router as assignmentsRouter };
