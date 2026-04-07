import { Router } from "express";

import { getOrganizationWorkspaceController } from "../controllers/organizationsController";
import { requireRole } from "../middleware/requireRole";
import { asyncHandler } from "../utils/asyncHandler";

const router = Router();

router.get(
  "/me/workspace",
  requireRole(["admin", "dispatcher", "operator", "field_worker"]),
  asyncHandler(getOrganizationWorkspaceController),
);

export { router as organizationsRouter };
