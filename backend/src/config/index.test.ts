import test from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { createRequire } from "node:module";

const requireModule = createRequire(__filename);

function loadConfigModule() {
  const modulePath = path.resolve(process.cwd(), "dist/config/index.js");
  const resolvedModulePath = requireModule.resolve(modulePath);
  delete requireModule.cache[resolvedModulePath];
  return requireModule(modulePath) as {
    config: {
      port: number;
      supabaseUrl: string;
      supabaseServiceRoleKey: string;
    };
  };
}

test("config throws when PORT is missing", async () => {
  const originalPort = process.env.PORT;
  const originalSupabaseUrl = process.env.SUPABASE_URL;

  process.env.PORT = "";
  process.env.SUPABASE_URL = "https://example.supabase.co";

  assert.throws(loadConfigModule, /Missing required environment variable: PORT/);

  process.env.PORT = originalPort;
  process.env.SUPABASE_URL = originalSupabaseUrl;
});

test("config throws when SUPABASE_URL is missing", async () => {
  const originalPort = process.env.PORT;
  const originalSupabaseUrl = process.env.SUPABASE_URL;
  const originalServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  process.env.PORT = "3000";
  process.env.SUPABASE_URL = "";
  process.env.SUPABASE_SERVICE_ROLE_KEY = "service-role-key";

  assert.throws(loadConfigModule, /Missing required environment variable: SUPABASE_URL/);

  process.env.PORT = originalPort;
  process.env.SUPABASE_URL = originalSupabaseUrl;
  process.env.SUPABASE_SERVICE_ROLE_KEY = originalServiceRoleKey;
});

test("config throws when SUPABASE_SERVICE_ROLE_KEY is missing", async () => {
  const originalPort = process.env.PORT;
  const originalSupabaseUrl = process.env.SUPABASE_URL;
  const originalServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  process.env.PORT = "3000";
  process.env.SUPABASE_URL = "https://example.supabase.co";
  process.env.SUPABASE_SERVICE_ROLE_KEY = "";

  assert.throws(
    loadConfigModule,
    /Missing required environment variable: SUPABASE_SERVICE_ROLE_KEY/,
  );

  process.env.PORT = originalPort;
  process.env.SUPABASE_URL = originalSupabaseUrl;
  process.env.SUPABASE_SERVICE_ROLE_KEY = originalServiceRoleKey;
});

test("config exports strict values when required env variables are present", async () => {
  const originalPort = process.env.PORT;
  const originalSupabaseUrl = process.env.SUPABASE_URL;
  const originalServiceRoleKey = process.env.SUPABASE_SERVICE_ROLE_KEY;

  process.env.PORT = "3000";
  process.env.SUPABASE_URL = "https://example.supabase.co";
  process.env.SUPABASE_SERVICE_ROLE_KEY = "service-role-key";

  const { config } = loadConfigModule();

  assert.equal(config.port, 3000);
  assert.equal(config.supabaseUrl, "https://example.supabase.co");
  assert.equal(config.supabaseServiceRoleKey, "service-role-key");

  process.env.PORT = originalPort;
  process.env.SUPABASE_URL = originalSupabaseUrl;
  process.env.SUPABASE_SERVICE_ROLE_KEY = originalServiceRoleKey;
});
