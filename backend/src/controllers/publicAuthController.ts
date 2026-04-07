import type { Request, Response } from "express";

import type {
  CreateOrganizationSignUpInput,
  JoinOrganizationSignUpInput,
} from "../schemas/publicAuthSchemas";
import {
  listAvailableOrganizations,
  signUpAsOrganization,
  signUpForOrganization,
} from "../services/publicAuthService";
import { getValidatedBody } from "../utils/requestContext";

export async function listAvailableOrganizationsController(
  _request: Request,
  response: Response,
) {
  const organizations = await listAvailableOrganizations();
  response.status(200).json({ data: organizations });
}

export async function signUpForOrganizationController(
  request: Request,
  response: Response,
) {
  const account = await signUpForOrganization(
    getValidatedBody<JoinOrganizationSignUpInput>(request),
  );

  response.status(201).json({ data: account });
}

export async function signUpAsOrganizationController(
  request: Request,
  response: Response,
) {
  const account = await signUpAsOrganization(
    getValidatedBody<CreateOrganizationSignUpInput>(request),
  );

  response.status(201).json({ data: account });
}
