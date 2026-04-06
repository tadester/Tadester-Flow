import test from "node:test";
import assert from "node:assert/strict";
import path from "node:path";
import { createRequire } from "node:module";

const requireModule = createRequire(__filename);

function loadConfigModule() {
  const modulePath = path.resolve(process.cwd(), "dist/config/index.js");
  const resolvedModulePath = requireModule.resolve(modulePath);
  delete requireModule.cache[resolvedModulePath];
  return requireModule(modulePath) as { config: { port: number; supabaseUrl: string } };
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

  process.env.PORT = "3000";
  process.env.SUPABASE_URL = "";

  assert.throws(loadConfigModule, /Missing required environment variable: SUPABASE_URL/);

  process.env.PORT = originalPort;
  process.env.SUPABASE_URL = originalSupabaseUrl;
});

test("config exports strict values when required env variables are present", async () => {
  const originalPort = process.env.PORT;
  const originalSupabaseUrl = process.env.SUPABASE_URL;

  process.env.PORT = "3000";
  process.env.SUPABASE_URL = "https://example.supabase.co";

  const { config } = loadConfigModule();

  assert.equal(config.port, 3000);
  assert.equal(config.supabaseUrl, "https://example.supabase.co");

  process.env.PORT = originalPort;
  process.env.SUPABASE_URL = originalSupabaseUrl;
});
