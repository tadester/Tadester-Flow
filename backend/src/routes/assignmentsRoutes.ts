import { Router } from "express";

import { createAssignmentController } from "../controllers/assignmentsController";
import { requireRole } from "../middleware/requireRole";
import { validateBody } from "../middleware/validate";
import { createAssignmentSchema } from "../schemas/assignmentSchemas";
import { asyncHandler } from "../utils/asyncHandler";

const router = Router();

router.post(
  "/",
  requireRole(["admin", "dispatcher", "operator"]),
  validateBody(createAssignmentSchema),
  asyncHandler(createAssignmentController),
);

export { router as assignmentsRouter };
