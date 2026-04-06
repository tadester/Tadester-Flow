# Backend Supabase

This directory is the home for the MVP operational Supabase schema, migrations,
seed data, and validation checks for Tadester Ops Phase 2.

## Structure

- `config.toml`
- `seed.sql`
- `migrations/`

## Migration Order

1. `001_create_extensions_and_base_helpers.sql`
2. `002_create_organizations_table.sql`
3. `003_create_profiles_table.sql`
4. `004_create_locations_table.sql`
5. `005_create_jobs_table.sql`
6. `006_create_job_assignments_table.sql`
7. `007_create_worker_location_pings_table.sql`
8. `008_create_location_events_table.sql`
9. `009_create_waitlist_leads_table.sql`
10. `010_add_indexes.sql`
11. `011_enable_rls.sql`
12. `012_create_rls_helper_functions.sql`
13. `013_create_rls_policies.sql`
14. `014_create_updated_at_triggers.sql`
15. `015_seed_mvp_data.sql`
16. `016_validation_checks.sql`

The landing-page waitlist remains separate from the operational schema work in
this backend-owned Supabase workspace.
