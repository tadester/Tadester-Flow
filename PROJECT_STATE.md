# Project State

## Repository Layout

- `landing-page/`: Next.js App Router marketing site and waitlist flow
- `backend/`: Backend workspace, including the Phase 2 Supabase schema area
- `mobile-app/`: Existing Flutter application

## Current Phase

- Repository structure initialized
- Landing page MVP UI assembled
- Waitlist form UI and validation added
- Waitlist API route connected to the live Supabase waitlist table
- Privacy, Terms, and custom 404 pages added
- Backend Supabase workspace initialized for Phase 2 database architecture
- Phase 2 MVP operational migration set scaffolded under `backend/supabase`
- Phase 3 backend Node.js + TypeScript scaffold created on its own branch
- Phase 3 Docker and docker-compose scaffolding added for backend local container runs
- Phase 3 backend GitHub Actions CI/CD workflow added with backend-only path filtering
- Phase 3 backend now includes real health and config tests instead of a no-op test script
- Phase 4 API surface branch now includes modular routes, controllers, services, auth middleware, and Zod validation for jobs, locations, assignments, and worker status
- Phase 4 now also includes a standalone Google Maps-based `RoutingService` for daily worker ETAs with safe fallback behavior
- Phase 4 now also includes a standalone `GeofenceService` with Haversine distance checks, transition-based event creation, and ping accuracy filtering
- Phase 4 now includes the worker tracking ingestion pipeline, async geofence triggering, and scheduled stale-worker inactivity checks
- Phase 5 mobile foundation is in progress on its own branch with Flutter feature architecture, Supabase auth flow, and mock-backed jobs UI

## Landing Page Status

- App Router, TypeScript, and Tailwind scaffold are in place
- Homepage includes navbar, hero, waitlist, features, operator quote, and footer
- Reusable UI components exist for inputs, select fields, buttons, and status messages
- Supabase browser and server helpers are present
- Shared waitlist types and validation helpers are present
- Supabase `public.waitlist` table exists with UUID primary key, `email`, `company_size`, `source`, and `created_at`
- Case-insensitive unique index on waitlist email is configured
- Row Level Security is enabled with public insert allowed and public reads blocked
- Local testing confirms the landing page and waitlist submission flow are working
- Local env setup uses `landing-page/.env.local` with Supabase URL and publishable key
- Landing page image assets and logo files have been added to `landing-page/public/images`
- Navbar uses the supplied `OPS.png` asset as the brand logo
- Hero, map, and operator image files are present in `landing-page/public/images`
- Hero, operator quote, and routing sections now use the supplied image assets directly
- Hero overlay readability and routing-map crop/alignment have been manually tuned against the current assets
- Site metadata icon is now set from the supplied image assets
- Routing section now uses `routing-map.png` as its source asset
- Routing visual has been simplified to a clean image-only presentation
- Root `netlify.toml` is configured to build from the `landing-page` subdirectory with the Next.js Netlify plugin
- Marketing copy no longer positions the product as Edmonton-only and now speaks to field teams worldwide
- Phase 2 seed data has been hardened for safer reruns of demo pings, events, and waitlist leads

## Remaining Setup

- Install `landing-page` dependencies
- Run local verification for `npm run build` and linting
- Run the new backend Supabase migrations against a project and verify seed/RLS behavior
- Configure backend env values including `SUPABASE_SERVICE_ROLE_KEY` in local/dev and hosting environments
- Add a real `GOOGLE_MAPS_API_KEY` in backend environments before using route ETA calculations
- Verify Phase 4 endpoints against a live Supabase project with real JWTs and role-aware access
- Verify `docker compose up --build` locally against the new backend container setup
- Replace `mobile-app/.env` placeholder values with real Supabase credentials before running the Flutter app against live auth
- Validate the mobile Phase 5 auth and jobs flow on-device or emulator against the live Supabase project
