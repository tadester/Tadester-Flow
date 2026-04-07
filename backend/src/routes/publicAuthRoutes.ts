import { Router } from "express";

import {
  listAvailableOrganizationsController,
  signUpAsOrganizationController,
  signUpForOrganizationController,
} from "../controllers/publicAuthController";
import {
  createOrganizationSignUpSchema,
  joinOrganizationSignUpSchema,
} from "../schemas/publicAuthSchemas";
import { asyncHandler } from "../utils/asyncHandler";
import { validateBody } from "../middleware/validate";

const router = Router();

router.get("/organizations", asyncHandler(listAvailableOrganizationsController));
router.post(
  "/signup/join",
  validateBody(joinOrganizationSignUpSchema),
  asyncHandler(signUpForOrganizationController),
);
router.post(
  "/signup/organization",
  validateBody(createOrganizationSignUpSchema),
  asyncHandler(signUpAsOrganizationController),
);

export { router as publicAuthRouter };
