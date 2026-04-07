# Backend API Layer

This folder contains the Express router layer.

## Current Files

- `index.ts`: combines API routes
- `health.ts`: health endpoint

## Responsibility

Keep route definitions and transport-level composition here. As the backend grows, additional route modules should be added here and push business logic down into services.
