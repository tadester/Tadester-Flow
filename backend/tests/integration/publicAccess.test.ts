import type { Express } from "express";
import request from "supertest";

import {
  createAdminClient,
  createAnonClient,
  getSecurityTestConfig,
} from "./helpers/supabaseTestUtils";

const configState = getSecurityTestConfig();

if (!configState.enabled) {
  describe.skip("public access restrictions", () => {
    it("requires live Supabase security env vars", () => {
      expect(configState.missing.length).toBeGreaterThan(0);
    });
  });
} else {
  const { config } = configState;

  describe("public access restrictions", () => {
    let app: Express;

    beforeAll(() => {
      process.env.PORT = process.env.PORT || "3000";
      process.env.SUPABASE_URL = config.supabaseUrl;
      process.env.SUPABASE_SERVICE_ROLE_KEY = config.supabaseServiceRoleKey;

      const appModule = require("../../src/app") as {
        createApp: () => Express;
      };
      app = appModule.createApp();
    });

    it("should block unauthenticated backend access to jobs, locations, assignments, workers, and tracking", async () => {
      const responses = await Promise.all([
        request(app).get("/api/jobs"),
        request(app).get("/api/locations"),
        request(app).post("/api/assignments").send({}),
        request(app).get("/api/workers/test-worker/status"),
        request(app).post("/api/tracking/ping").send({}),
      ]);

      responses.forEach((response) => {
        expect(response.status).toBe(401);
        expect(response.body.error.code).toBe("UNAUTHORIZED");
      });
    });

    it("should allow anonymous waitlist inserts but block anonymous waitlist reads", async () => {
      const anonClient = createAnonClient(config);
      const adminClient = createAdminClient(config);
      const email = `security-test-${Date.now()}@example.com`;

      const { error: insertError } = await anonClient.from("waitlist_leads").insert({
        email,
        company: "Tadester Ops QA",
        message: "Public insert validation",
      });

      expect(insertError).toBeNull();

      const { data, error: readError } = await anonClient
        .from("waitlist_leads")
        .select("id, email")
        .eq("email", email);

      if (readError) {
        expect(readError.message).toBeTruthy();
      } else {
        expect(data ?? []).toEqual([]);
      }

      await adminClient.from("waitlist_leads").delete().eq("email", email);
    });
  });
}
