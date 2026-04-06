# Backend

Node.js + TypeScript backend scaffold for Tadester Ops Phase 3.

## Included

- Express app bootstrap
- Strict environment loading
- Winston logging
- `/api/health` endpoint
- Supabase Phase 2 schema workspace in `supabase/`

## Run

1. Copy `.env.example` to `.env`
2. Fill in required environment values
3. Run `npm install`
4. Run `npm run dev`

## Docker

- Build and run with `docker compose up --build` from the repo root
- Backend is exposed on port `3000`
- Health check is available at `/health`
