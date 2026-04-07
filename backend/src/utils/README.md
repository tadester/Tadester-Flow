# Backend Utilities

This folder contains reusable backend helpers.

## Current File

- `logger.ts`: Winston logger configuration

## Rule Of Thumb

If code is generic, shared, and not part of one business flow, it probably belongs here. If it starts to encode product rules, it should move to `services/` or `domain/`.
