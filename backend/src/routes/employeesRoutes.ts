import { Router } from "express";

import { listEmployeesController } from "../controllers/employeesController";
import { requireRole } from "../middleware/requireRole";
import { asyncHandler } from "../utils/asyncHandler";

const router = Router();

router.get(
  "/",
  requireRole(["admin", "dispatcher", "operator"]),
  asyncHandler(listEmployeesController),
);

export { router as employeesRouter };
