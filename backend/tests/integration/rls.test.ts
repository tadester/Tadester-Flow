import {
  createAdminClient,
  createAuthedClient,
  getSecurityTestConfig,
  readOwnProfileIds,
  signInTestUser,
} from "./helpers/supabaseTestUtils";

const configState = getSecurityTestConfig();

if (!configState.enabled) {
  describe.skip("Supabase RLS cross-user access", () => {
    it("requires live Supabase security env vars", () => {
      expect(configState.missing.length).toBeGreaterThan(0);
    });
  });
} else {
  const { config } = configState;

  describe("Supabase RLS cross-user access", () => {
    it("should not leak worker A job assignments to worker B", async () => {
      const adminClient = createAdminClient(config);
      const profileIds = await readOwnProfileIds(adminClient, [
        config.workerAEmail,
        config.workerBEmail,
      ]);
      const workerASession = await signInTestUser(config, {
        email: config.workerAEmail,
        password: config.workerAPassword,
      });
      const workerBSession = await signInTestUser(config, {
        email: config.workerBEmail,
        password: config.workerBPassword,
      });
      const workerAId = profileIds[config.workerAEmail] ?? workerASession.userId;
      const attackerClient = createAuthedClient(config, workerBSession.accessToken);

      const { data, error } = await attackerClient
        .from("job_assignments")
        .select("id, worker_profile_id")
        .eq("worker_profile_id", workerAId);

      if (error) {
        expect(error.message).toBeTruthy();
        return;
      }

      expect(data ?? []).toEqual([]);
    });

    it("should not leak worker A location pings to worker B", async () => {
      const adminClient = createAdminClient(config);
      const profileIds = await readOwnProfileIds(adminClient, [config.workerAEmail]);
      const workerBSession = await signInTestUser(config, {
        email: config.workerBEmail,
        password: config.workerBPassword,
      });
      const workerAId = profileIds[config.workerAEmail];
      const attackerClient = createAuthedClient(config, workerBSession.accessToken);

      const { data, error } = await attackerClient
        .from("worker_location_pings")
        .select("id, worker_profile_id")
        .eq("worker_profile_id", workerAId);

      if (error) {
        expect(error.message).toBeTruthy();
        return;
      }

      expect(data ?? []).toEqual([]);
    });

    it("should not leak worker A geofence events to worker B", async () => {
      const adminClient = createAdminClient(config);
      const profileIds = await readOwnProfileIds(adminClient, [config.workerAEmail]);
      const workerBSession = await signInTestUser(config, {
        email: config.workerBEmail,
        password: config.workerBPassword,
      });
      const workerAId = profileIds[config.workerAEmail];
      const attackerClient = createAuthedClient(config, workerBSession.accessToken);

      const { data, error } = await attackerClient
        .from("location_events")
        .select("id, worker_profile_id")
        .eq("worker_profile_id", workerAId);

      if (error) {
        expect(error.message).toBeTruthy();
        return;
      }

      expect(data ?? []).toEqual([]);
    });
  });
}
