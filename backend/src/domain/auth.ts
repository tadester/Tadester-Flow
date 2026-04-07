export type AppRole = "admin" | "dispatcher" | "operator" | "field_worker";

export type AuthenticatedUser = {
  id: string;
  email: string;
  role: AppRole;
  organizationId: string;
  status: "active" | "inactive";
};

export type JwtClaims = {
  sub?: string;
  email?: string;
  role?: string;
};
