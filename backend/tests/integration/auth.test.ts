import {
  createAnonClient,
  createAuthedClient,
  getSecurityTestConfig,
  signInTestUser,
} from "./helpers/supabaseTestUtils";

const configState = getSecurityTestConfig();

if (!configState.enabled) {
  describe.skip("Supabase auth flow behavior", () => {
    it("requires live Supabase security env vars", () => {
      expect(configState.missing.length).toBeGreaterThan(0);
    });
  });
} else {
  const { config } = configState;

  describe("Supabase auth flow behavior", () => {
    it("should keep an access token usable across a simulated app restart", async () => {
      const session = await signInTestUser(config, {
        email: config.workerAEmail,
        password: config.workerAPassword,
      });
      const restartedClient = createAuthedClient(config, session.accessToken);

      const { data, error } = await restartedClient.auth.getUser(session.accessToken);

      expect(error).toBeNull();
      expect(data.user?.id).toBe(session.userId);
    });

    it("should clear the local session on logout", async () => {
      const session = await signInTestUser(config, {
        email: config.workerAEmail,
        password: config.workerAPassword,
      });

      const { error: signOutError } = await session.client.auth.signOut();
      expect(signOutError).toBeNull();

      const { data, error } = await session.client.auth.getSession();

      expect(error).toBeNull();
      expect(data.session).toBeNull();
    });

    it("should reject clearly invalid bearer tokens", async () => {
      const anonymousClient = createAnonClient(config);

      const { data, error } = await anonymousClient.auth.getUser(
        "definitely-not-a-real-token",
      );

      expect(data.user).toBeNull();
      expect(error).not.toBeNull();
    });

    it.skip(
      "should reject previously issued access tokens immediately after logout once server-side token revocation is enforced",
      async () => {
        // Supabase access tokens can remain valid until expiry even after sign out.
        // This test is intentionally skipped until the platform adopts stricter revocation semantics.
      },
    );
  });
}
