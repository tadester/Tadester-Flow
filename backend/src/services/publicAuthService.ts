import { randomUUID } from "crypto";

import { BadRequestError } from "../utils/errors";
import { handleSupabaseError } from "../utils/supabaseErrors";
import type {
  CreateOrganizationSignUpInput,
  JoinOrganizationSignUpInput,
} from "../schemas/publicAuthSchemas";
import { supabaseAdmin } from "./supabaseService";

type OrganizationOption = {
  id: string;
  name: string;
  slug: string;
};

type CreatedAccountResult = {
  organization: OrganizationOption;
  profile: {
    id: string;
    email: string;
    full_name: string;
    phone: string | null;
    role: "admin" | "field_worker";
    status: "active";
  };
};

type OrganizationRow = {
  id: string;
  name: string;
  slug: string;
  status: string;
};

export async function listAvailableOrganizations(): Promise<OrganizationOption[]> {
  const { data, error } = await supabaseAdmin
    .from("organizations")
    .select("id, name, slug")
    .eq("status", "active")
    .order("name", { ascending: true })
    .returns<OrganizationOption[]>();

  if (error) {
    handleSupabaseError(error, "Failed to list organizations.");
  }

  return data ?? [];
}

export async function signUpForOrganization(
  input: JoinOrganizationSignUpInput,
): Promise<CreatedAccountResult> {
  const organization = await getActiveOrganization(input.organizationId);
  const userId = await createConfirmedAuthUser({
    email: input.email,
    password: input.password,
    fullName: input.fullName,
    phone: input.phone,
    role: "field_worker",
    organizationId: organization.id,
  });

  try {
    await insertProfile({
      id: userId,
      organizationId: organization.id,
      email: input.email,
      fullName: input.fullName,
      phone: input.phone,
      role: "field_worker",
    });
  } catch (error) {
    await cleanupAuthUser(userId);
    throw error;
  }

  return {
    organization,
    profile: {
      id: userId,
      email: input.email,
      full_name: input.fullName,
      phone: normalizeOptionalText(input.phone),
      role: "field_worker",
      status: "active",
    },
  };
}

export async function signUpAsOrganization(
  input: CreateOrganizationSignUpInput,
): Promise<CreatedAccountResult> {
  const organization = await createOrganization(input.organizationName);

  let userId: string | null = null;

  try {
    userId = await createConfirmedAuthUser({
      email: input.email,
      password: input.password,
      fullName: input.fullName,
      phone: input.phone,
      role: "admin",
      organizationId: organization.id,
    });

    await insertProfile({
      id: userId,
      organizationId: organization.id,
      email: input.email,
      fullName: input.fullName,
      phone: input.phone,
      role: "admin",
    });
  } catch (error) {
    if (userId) {
      await cleanupAuthUser(userId);
    }

    await cleanupOrganization(organization.id);
    throw error;
  }

  return {
    organization,
    profile: {
      id: userId,
      email: input.email,
      full_name: input.fullName,
      phone: normalizeOptionalText(input.phone),
      role: "admin",
      status: "active",
    },
  };
}

async function getActiveOrganization(organizationId: string): Promise<OrganizationOption> {
  const { data, error } = await supabaseAdmin
    .from("organizations")
    .select("id, name, slug, status")
    .eq("id", organizationId)
    .eq("status", "active")
    .maybeSingle<OrganizationRow>();

  if (error) {
    handleSupabaseError(error, "Failed to fetch organization.");
  }

  if (!data) {
    throw new BadRequestError("Selected organization is not available.");
  }

  return {
    id: data.id,
    name: data.name,
    slug: data.slug,
  };
}

async function createOrganization(name: string): Promise<OrganizationOption> {
  const slug = await buildUniqueOrganizationSlug(name);
  const { data, error } = await supabaseAdmin
    .from("organizations")
    .insert({
      id: randomUUID(),
      name: name.trim(),
      slug,
      status: "active",
    })
    .select("id, name, slug")
    .single<OrganizationOption>();

  if (error) {
    handleSupabaseError(error, "Failed to create organization.");
  }

  if (!data) {
    throw new BadRequestError("Organization could not be created.");
  }

  return data;
}

async function buildUniqueOrganizationSlug(name: string): Promise<string> {
  const baseSlug = slugify(name);

  if (!baseSlug) {
    throw new BadRequestError("Organization name must include letters or numbers.");
  }

  const { data, error } = await supabaseAdmin
    .from("organizations")
    .select("slug")
    .ilike("slug", `${baseSlug}%`)
    .returns<Array<{ slug: string }>>();

  if (error) {
    handleSupabaseError(error, "Failed to validate organization slug.");
  }

  const existing = new Set((data ?? []).map((row) => row.slug));

  if (!existing.has(baseSlug)) {
    return baseSlug;
  }

  let suffix = 2;
  while (existing.has(`${baseSlug}-${suffix}`)) {
    suffix += 1;
  }

  return `${baseSlug}-${suffix}`;
}

async function createConfirmedAuthUser(input: {
  email: string;
  password: string;
  fullName: string;
  phone?: string;
  role: "admin" | "field_worker";
  organizationId: string;
}): Promise<string> {
  const { data, error } = await supabaseAdmin.auth.admin.createUser({
    email: input.email,
    password: input.password,
    email_confirm: true,
    user_metadata: {
      full_name: input.fullName,
      phone: normalizeOptionalText(input.phone),
      role: input.role,
      organization_id: input.organizationId,
      seeded: false,
    },
  });

  if (error || !data.user) {
    throw new BadRequestError(error?.message ?? "Unable to create account.");
  }

  return data.user.id;
}

async function insertProfile(input: {
  id: string;
  organizationId: string;
  email: string;
  fullName: string;
  phone?: string;
  role: "admin" | "field_worker";
}) {
  const { error } = await supabaseAdmin.from("profiles").insert({
    id: input.id,
    organization_id: input.organizationId,
    email: input.email,
    full_name: input.fullName,
    role: input.role,
    status: "active",
    phone: normalizeOptionalText(input.phone),
  });

  if (error) {
    handleSupabaseError(error, "Failed to create organization profile.");
  }
}

async function cleanupAuthUser(userId: string) {
  await supabaseAdmin.auth.admin.deleteUser(userId).catch(() => undefined);
}

async function cleanupOrganization(organizationId: string) {
  const { error } = await supabaseAdmin
    .from("organizations")
    .delete()
    .eq("id", organizationId);

  if (error) {
    return;
  }
}

function normalizeOptionalText(value: string | undefined): string | null {
  const trimmed = value?.trim();
  return trimmed ? trimmed : null;
}

function slugify(value: string): string {
  return value
    .toLowerCase()
    .trim()
    .replace(/[^a-z0-9]+/g, "-")
    .replace(/^-+|-+$/g, "")
    .slice(0, 48);
}
