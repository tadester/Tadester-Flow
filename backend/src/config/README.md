# Backend Config

This folder owns environment loading and validation.

## Current Files

- `index.ts`: loads `.env` and throws if required values are missing
- `index.test.ts`: verifies fail-fast behavior

## Design Rule

The backend should never start half-configured. Missing required env vars are treated as startup errors, not runtime warnings.
