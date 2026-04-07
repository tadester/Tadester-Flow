# Backend Source

This folder contains the runtime source code for the backend service.

## Startup Flow

1. `server.ts` starts the HTTP server
2. `app.ts` creates the Express application
3. `api/` mounts route groups
4. `config/` validates environment variables
5. `utils/` provides shared helpers like logging

## Current Shape

The source tree is still intentionally small on this branch:

- health route
- strict config loading
- basic test coverage for boot and config

## Subfolders

- `api/`: route composition
- `config/`: environment loading and validation
- `domain/`: domain types and reserved business concepts
- `services/`: reserved service-layer logic
- `utils/`: shared helpers
- `workers/`: reserved background-process area
