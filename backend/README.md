# Backend

This folder contains the Tadester Ops backend service and the backend-owned Supabase workspace.

## Responsibilities

- run the Express API
- validate backend environment variables
- provide backend logging and startup behavior
- define backend containerization and CI entrypoints
- own the operational Supabase migration history

## Important Files

- `package.json`: scripts and dependencies
- `tsconfig.json`: TypeScript compiler configuration
- `Dockerfile`: production container definition
- `.env.example`: environment template
- `src/`: runtime source code
- `supabase/`: schema, seed, and migration assets

## Run Locally

1. Copy `.env.example` to `.env`
2. Fill in the required values
3. Run `npm install`
4. Run `npm run dev`

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

On this branch, the backend is scaffold-first and operationally clean, but still intentionally narrow in terms of API surface.
