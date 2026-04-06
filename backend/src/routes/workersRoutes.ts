import { Router } from "express";

import { getWorkerStatusController } from "../controllers/workersController";
import { asyncHandler } from "../utils/asyncHandler";

const router = Router();

router.get("/:id/status", asyncHandler(getWorkerStatusController));

export { router as workersRouter };
