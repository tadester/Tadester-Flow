# Tadester Ops Backend

Node.js + TypeScript backend for the Tadester Ops MVP.

This service currently includes:

- Express API with strict config loading
- Supabase-backed auth and data access
- Health endpoint
- Jobs, locations, assignments, and worker-status API surface
- Worker GPS ingestion pipeline
- Async geofence processing
- Daily routing/ETA service using Google Maps Distance Matrix
- Scheduled stale-worker inactivity checks

## What You Need Installed

Required:

- Node.js 20+
- npm

Optional:

- Docker Desktop if you want to run the backend in containers
- A Supabase project with the Phase 2 schema applied
- A Google Maps API key if you want routing ETA calculations to use live map data

## Environment Variables

Copy `.env.example` to `.env` inside `backend/`.

Required:

- `PORT`
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

Optional:

- `GOOGLE_MAPS_API_KEY`

Notes:

- `SUPABASE_SERVICE_ROLE_KEY` is required because the backend reads and writes operational data using the service-role client.
- `GOOGLE_MAPS_API_KEY` is only needed for live route distance and ETA calculations.
- If `GOOGLE_MAPS_API_KEY` is missing, the routing service safely falls back to returning sorted jobs without route legs.

Example:

```env
PORT=4000
SUPABASE_URL=https://your-project.supabase.co
SUPABASE_SERVICE_ROLE_KEY=your_service_role_key
GOOGLE_MAPS_API_KEY=your_google_maps_api_key
```

## Install and Run Locally

From the repo root:

```bash
cd backend
npm install
npm run dev
```

The backend will start on the port defined in `.env`.

Useful commands:

```bash
npm run build
npm run lint
npm test
npm run dev
```

Health check routes:

- `/health`
- `/api/health`

## Validation Commands

- `npm run lint`
- `npm run build`
- `npm test`

## Folder Map

- `src/`: application source
- `supabase/`: backend-owned database workspace
- `dist/`: generated build output

## Current Maturity

From the repo root:

```bash
docker compose up --build
```

Current Docker setup:

- backend runs on `http://localhost:3000`
- local Postgres runs on `localhost:5432`

Important:

- The compose file currently uses placeholder Supabase values for local container startup.
- If you want real backend behavior through Docker, replace those with your actual backend env values.

## Health Check

Available at:

- `GET /health`
- `GET /api/health`

Expected response:

```json
{
  "status": "ok",
  "timestamp": "2026-04-06T00:00:00.000Z",
  "version": "0.1.0"
}
```

## Current API Surface

Protected routes require a Supabase JWT in:

```http
Authorization: Bearer <token>
```

Current routes:

- `POST /api/jobs`
- `GET /api/jobs`
- `GET /api/jobs/:id`
- `PATCH /api/jobs/:id/status`
- `POST /api/locations`
- `GET /api/locations`
- `POST /api/assignments`
- `GET /api/workers/:id/status`
- `POST /api/tracking/ping`

## Authentication and Roles

The backend decodes the Supabase bearer token, loads the matching profile from Supabase, and attaches the user context to the request.

Supported roles:

- `admin`
- `dispatcher`
- `operator`
- `field_worker`

Role behavior currently enforced:

- staff roles can manage jobs, locations, and assignments
- field workers can post tracking pings
- worker-specific endpoints restrict access appropriately

## Tracking Pipeline

Endpoint:

- `POST /api/tracking/ping`

Payload:

```json
{
  "latitude": 53.5461,
  "longitude": -113.4938,
  "accuracy_meters": 8,
  "timestamp": "2026-04-06T12:00:00.000Z"
}
```

Flow:

1. validate request body with Zod
2. require authenticated `field_worker`
3. store raw GPS ping in `worker_location_pings`
4. mark the worker profile status as `active`
5. queue geofence evaluation in the background
6. return immediately with:

```json
{
  "success": true
}
```

Design goals:

- non-blocking response
- geofence work happens asynchronously
- ingestion route should remain resilient under frequent ping traffic

## Geofence Behavior

`GeofenceService`:

- ignores pings where `accuracy_meters > 50`
- loads active assigned locations for the worker
- calculates point-to-center distance with the Haversine formula
- determines `inside` or `outside`
- checks the last known geofence event
- only writes a new event when state changes

Transition rules:

- outside -> inside => `geofence_enter`
- inside -> outside => `geofence_exit`
- no change => no event
- first ping => initialize state only, no event

Note:

- current schema stores ping details for geofence events inside `location_events.metadata`

## Routing Behavior

`RoutingService`:

- fetches a worker's assigned jobs for a given day
- keeps only route-eligible jobs with valid `scheduled_start_at`
- sorts by scheduled start time ascending
- loads linked location coordinates
- uses Google Maps Distance Matrix with `driving` mode
- uses the worker's last known location as the first origin when available
- falls back safely if Google Maps fails or no API key is provided

Return shape includes:

- `ordered_jobs`
- `legs`
- `total_distance`
- `total_time`

## Stale Worker Scheduler

`StaleWorkerService` runs on an interval from server startup.

Current behavior:

- every 5 minutes
- find active field workers whose latest ping is older than 10 minutes
- mark them `inactive`

Important:

- worker profile `status` is currently being used as live activity state
- a new ping marks the worker back to `active`

## Testing

The backend currently has automated coverage for:

- config validation
- middleware validation and role checks
- routing fallback behavior
- geofence transition behavior
- ingestion service behavior
- stale worker inactivity logic

Run:

```bash
npm run build
npm run lint
npm test
```

## Phase 4 Notes

This backend is locally verified, but some behavior still needs live environment validation:

- real Supabase JWT flow against your deployed backend
- live writes to `worker_location_pings` and `location_events`
- real Google Maps API calls with your production key
- scheduler behavior over time in hosting
