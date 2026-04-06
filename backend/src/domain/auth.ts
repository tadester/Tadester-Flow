export type AppRole = "admin" | "dispatcher" | "operator" | "field_worker";

export type AuthenticatedUser = {
  id: string;
  email: string;
  role: AppRole;
  organizationId: string;
};

export type JwtClaims = {
  sub?: string;
  email?: string;
  role?: string;
};
