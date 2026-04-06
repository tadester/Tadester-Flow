# Tadester Ops Monorepo

This repository contains the current Tadester Ops MVP surfaces:

- [landing-page/](/Users/ktr/Documents/GitHub/tadesterflow/landing-page): Next.js marketing site and waitlist flow
- [backend/](/Users/ktr/Documents/GitHub/tadesterflow/backend): Node.js + TypeScript API and operational services
- [mobile-app/](/Users/ktr/Documents/GitHub/tadesterflow/mobile-app): Flutter mobile app

## Quick Start

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

### Docker

From the repo root:

```bash
docker compose up --build
```

## Backend Requirements

To run the backend properly, install:

- Node.js 20+
- npm

Optional but useful:

- Docker Desktop

Required backend env variables are documented in [backend/README.md](/Users/ktr/Documents/GitHub/tadesterflow/backend/README.md).

## Current Backend Capabilities

The backend currently includes:

- health endpoint
- jobs, locations, assignments, and worker-status API routes
- worker location ingestion
- async geofence processing
- stale worker scheduler
- routing ETA service with Google Maps fallback support

## Project Tracking

Current implementation state is tracked in [PROJECT_STATE.md](/Users/ktr/Documents/GitHub/tadesterflow/PROJECT_STATE.md).
