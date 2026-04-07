# Tadester Ops Pre-Flight QA Report

## 1. Security Findings
| Issue | Severity | File | Description |
| --- | --- | --- | --- |
| No confirmed hardcoded private secrets found in source scan | Info | repo-wide scan | The current scan did not find committed Google Maps private keys, Supabase service-role keys, or JWT secrets in maintained source files. Placeholder/test values are still present in docs, tests, and local compose config as expected. |
| Local Docker compose advertises a dummy service-role value in committed config | Low | `docker-compose.yml:10` | The committed compose file uses a placeholder service-role key. It is not a real secret, but it can confuse contributors into thinking the backend is safe to boot against production-like flows without a real secure env file. |
| Real RLS/auth security tests are env-gated and not exercised by default CI | High | `backend/tests/integration/auth.test.ts`, `backend/tests/integration/rls.test.ts`, `backend/tests/integration/publicAccess.test.ts` | The live Supabase security suite is now present, but it skips unless the required test credentials and keys are configured. That means production-like auth and RLS behavior is not yet continuously proven on every run. |

## 2. Backend Risks
| Endpoint | Issue | Risk Level |
| --- | --- | --- |
| `All authenticated /api/* operational routes` | The backend uses a service-role Supabase client, so application-layer auth and role checks are the real security boundary rather than database RLS | High |
| `GET /health`, `GET /api/health` | Public by design | Low |

## 3. Flutter Stability Issues
| Screen | Issue | Impact |
| --- | --- | --- |
| `mobile-app/lib/main.dart` | No top-level Flutter error boundary or guarded zone around async startup | Unhandled startup failures can terminate the app without graceful recovery or reporting. |
| `mobile-app/lib/features/tracking/presentation/screens/location_permission_screen.dart` | Multiple async actions (`_refreshPermissionState`, `_requestPermission`, `_startTracking`, `_stopTracking`) do not catch plugin/service exceptions | Permission-handler or geolocator failures can bubble into the UI and leave the screen stuck in a busy state or crash. |
| `mobile-app/lib/features/auth/presentation/screens/splash_screen.dart` | Splash logic only reacts to `whenData`; there is no explicit error branch for auth stream failures | A startup auth-stream failure can leave the app sitting on the loading screen without a recovery path. |

## 4. Production Readiness Checklist
| Component | Status (PASS/FAIL) | Notes |
| --- | --- | --- |
| Landing Page | PASS | Public landing page, waitlist form, and waitlist API are in place and locally/build verified. |
| Authentication | PASS | Backend JWT handling now verifies tokens against Supabase before attaching identity, and mobile auth flow is implemented. |
| Tracking Pipeline | PASS | Tracking ingestion route, async geofence trigger, stale-worker logic, and integration coverage are present and passing locally. |
| Geofence Engine | PASS | Deterministic geofence math and transition logic now have dedicated unit coverage, including boundary and duplicate-event cases. |
| RLS Security | FAIL | Supabase RLS schema and live security test suite exist, but the real-instance tests are currently skipped without dedicated security env configuration. |
| Container Health | PASS | Multi-stage Dockerfile, compose setup, strict env loading, and `/health` endpoint exist. No Docker `HEALTHCHECK` instruction yet, but there is no immediate deployment blocker from the container definition alone. |

## 5. Final Verdict
- NOT READY
- Top 3 blockers:
  1. Real Supabase RLS/auth integration tests are not configured to run in CI yet, so the most important security boundary is not continuously verified.
  2. The backend still relies on a service-role Supabase client for operational reads and writes, so any future app-layer authorization regression could bypass RLS protection.
  3. Logout-token revocation is not enforced as a guaranteed immediate security property, and the corresponding live test remains intentionally skipped until stricter semantics are chosen.
