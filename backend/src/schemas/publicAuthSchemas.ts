import { z } from "zod";

export const joinOrganizationSignUpSchema = z.object({
  organizationId: z.string().uuid(),
  fullName: z.string().trim().min(1),
  email: z.string().trim().email(),
  password: z.string().min(8),
  phone: z.string().trim().optional(),
});

export const createOrganizationSignUpSchema = z.object({
  organizationName: z.string().trim().min(2),
  fullName: z.string().trim().min(1),
  email: z.string().trim().email(),
  password: z.string().min(8),
  phone: z.string().trim().optional(),
});

export type JoinOrganizationSignUpInput = z.infer<
  typeof joinOrganizationSignUpSchema
>;
export type CreateOrganizationSignUpInput = z.infer<
  typeof createOrganizationSignUpSchema
>;
