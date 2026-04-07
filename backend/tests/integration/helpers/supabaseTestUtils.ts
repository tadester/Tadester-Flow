import { createClient, type SupabaseClient } from "@supabase/supabase-js";

type SecurityTestConfig = {
  supabaseUrl: string;
  supabaseAnonKey: string;
  supabaseServiceRoleKey: string;
  workerAEmail: string;
  workerAPassword: string;
  workerBEmail: string;
  workerBPassword: string;
};

type SecurityTestUserSession = {
  accessToken: string;
  refreshToken: string | null;
  userId: string;
  email: string;
  client: SupabaseClient;
};

type SecurityTestConfigEntry = {
  key: keyof SecurityTestConfig;
  env: string;
};

const CONFIG_KEYS: SecurityTestConfigEntry[] = [
  { key: "supabaseUrl", env: "SUPABASE_URL" },
  { key: "supabaseAnonKey", env: "SUPABASE_ANON_KEY" },
  { key: "supabaseServiceRoleKey", env: "SUPABASE_SERVICE_ROLE_KEY" },
  { key: "workerAEmail", env: "SECURITY_TEST_WORKER_A_EMAIL" },
  { key: "workerAPassword", env: "SECURITY_TEST_WORKER_A_PASSWORD" },
  { key: "workerBEmail", env: "SECURITY_TEST_WORKER_B_EMAIL" },
  { key: "workerBPassword", env: "SECURITY_TEST_WORKER_B_PASSWORD" },
];

export function getSecurityTestConfig():
  | { enabled: true; config: SecurityTestConfig }
  | { enabled: false; missing: string[] } {
  const values = Object.fromEntries(
    CONFIG_KEYS.map(({ key, env }) => [key, process.env[env]?.trim() ?? ""]),
  ) as Record<keyof SecurityTestConfig, string>;

  const missing = CONFIG_KEYS.filter(({ key }) => !values[key]).map(({ env }) => env);

  if (missing.length > 0) {
    return { enabled: false, missing };
  }

  return {
    enabled: true,
    config: values as SecurityTestConfig,
  };
}

export function createAnonClient(config: SecurityTestConfig): SupabaseClient {
  return createClient(config.supabaseUrl, config.supabaseAnonKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

export function createAdminClient(config: SecurityTestConfig): SupabaseClient {
  return createClient(config.supabaseUrl, config.supabaseServiceRoleKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
  });
}

export function createAuthedClient(
  config: SecurityTestConfig,
  accessToken: string,
): SupabaseClient {
  return createClient(config.supabaseUrl, config.supabaseAnonKey, {
    auth: {
      persistSession: false,
      autoRefreshToken: false,
    },
    global: {
      headers: {
        Authorization: `Bearer ${accessToken}`,
      },
    },
  });
}

export async function signInTestUser(
  config: SecurityTestConfig,
  credentials: { email: string; password: string },
): Promise<SecurityTestUserSession> {
  const client = createAnonClient(config);
  const { data, error } = await client.auth.signInWithPassword(credentials);

  if (error || !data.session || !data.user) {
    throw new Error(
      `Failed to sign in security test user ${credentials.email}: ${error?.message ?? "unknown error"}`,
    );
  }

  return {
    accessToken: data.session.access_token,
    refreshToken: data.session.refresh_token ?? null,
    userId: data.user.id,
    email: data.user.email ?? credentials.email,
    client,
  };
}

export async function readOwnProfileIds(
  adminClient: SupabaseClient,
  emails: readonly string[],
): Promise<Record<string, string>> {
  const { data, error } = await adminClient
    .from("profiles")
    .select("id, email")
    .in("email", [...emails]);

  if (error) {
    throw new Error(`Failed to fetch test profile ids: ${error.message}`);
  }

  return Object.fromEntries(
    (data ?? []).map((row) => [String(row.email), String(row.id)]),
  );
}
