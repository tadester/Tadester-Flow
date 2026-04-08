# Tadester Ops Monorepo

Tadester Ops is an operations platform for field crews. This monorepo contains the public lead funnel, the backend API and database workspace, and the Flutter operations app used by admins, dispatchers, operators, and field workers.

## Repo Structure

- `landing-page/`: Next.js marketing site, waitlist capture, and email-link auth pages
- `backend/`: Node.js + TypeScript API, tests, Docker setup, and Supabase migrations/scripts
- `mobile-app/`: Flutter app for organization sign-in, admin operations, worker jobs, routing, and tracking
- `PROJECT_STATE.md`: rolling implementation snapshot
- `docker-compose.yml`: local backend + Postgres composition

## Current Product State

What is already built:

- live landing page and waitlist capture
- Supabase schema with organizations, profiles, jobs, assignments, pings, and geofence events
- modular backend with auth, jobs, assignments, tracking ingestion, geofence handling, and routing
- Flutter app with org-aware auth, role-based dashboards, worker route map, and tracking controls

## Prerequisites

### Backend

- Node.js 20+
- npm
- Supabase project with the Tadester Ops schema applied

### Mobile App

- Flutter SDK
- Xcode for iOS builds
- CocoaPods for iOS dependency install
- a Google Maps API key for in-app route maps

## Environment Setup

### Backend

Create `backend/.env`:

```env
PORT=3000
SUPABASE_URL=your_supabase_project_url
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
GOOGLE_MAPS_API_KEY=your_google_maps_key
```

### Mobile App

Create or update `mobile-app/.env`:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_anon_key
BACKEND_API_URL=https://tadester-ops.onrender.com
GOOGLE_MAPS_API_KEY=your_google_maps_key
```

## Running The Project

### Landing Page

```bash
cd landing-page
npm install
npm run dev
```

### Backend

```bash
cd backend
npm install
npm run dev
```

Health checks:

- `http://localhost:3000/health`
- `http://localhost:3000/api/health`

### Mobile App

```bash
cd mobile-app
flutter pub get
flutter run
```

### iOS-specific rebuild after native changes

```bash
cd mobile-app
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

### macOS desktop rebuild after entitlement changes

```bash
cd mobile-app
flutter clean
flutter pub get
flutter run -d macos
```

## Demo Data And Tester Login Details

Seed demo workspace data from the backend:

```bash
cd backend
npm install
npm run seed:demo
```

Tester login details:

### Management

- `demo.north.admin@tadesterops.dev` / `password123`
- `demo.north.dispatcher@tadesterops.dev` / `password123`
- `demo.prairie.admin@tadesterops.dev` / `password123`
- `demo.prairie.operator@tadesterops.dev` / `password123`

### Workers

- `demo.north.worker.one@tadesterops.dev` / `password123`
- `demo.north.worker.two@tadesterops.dev` / `password123`
- `demo.prairie.worker.one@tadesterops.dev` / `password123`
- `demo.prairie.worker.two@tadesterops.dev` / `password123`

Best first tests:

- admin flow: `demo.north.admin@tadesterops.dev`
- worker flow: `demo.north.worker.one@tadesterops.dev`

## What To Test

### Admin flow

1. Sign in as `demo.north.admin@tadesterops.dev`
2. Open overview, jobs, workers, and settings
3. Create a location, create a job, and assign a worker
4. Use auto-assign to distribute jobs by proximity

### Worker flow

1. Sign in as `demo.north.worker.one@tadesterops.dev`
2. Open Jobs and tap into job detail
3. Open Route to see the ordered route and map
4. Open Settings and enable live tracking
5. Confirm the app requests location permission

## Known Platform Notes

- On iPhone, `Open app settings` can only open the Tadester Ops app settings page. Apple does not allow apps to deep-link directly into the nested `Location` page.
- On macOS, network client entitlements are enabled for Debug, Profile, and Release builds. If login still fails with `SocketException: Operation not permitted`, do a full clean rebuild so the new entitlements are picked up.
- Workers are marked `active` when a fresh location ping is received and `inactive` after 10 minutes without a new ping.

## Validation Commands

### Backend

```bash
cd backend
npm test
npm run lint
```

### Mobile App

```bash
cd mobile-app
flutter analyze
flutter test
```

## Additional Docs

- [backend/README.md](/Users/ktr/Developer/GitHub/tadesterflow/backend/README.md)
- [mobile-app/README.md](/Users/ktr/Developer/GitHub/tadesterflow/mobile-app/README.md)
- [PROJECT_STATE.md](/Users/ktr/Developer/GitHub/tadesterflow/PROJECT_STATE.md)
