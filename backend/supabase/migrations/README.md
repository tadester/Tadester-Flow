# Backend Migrations

This folder contains ordered SQL migrations for the backend-owned Supabase project.

## Naming Convention

Migrations are prefixed numerically so they apply in a deterministic order.

## What Belongs Here

- schema creation
- indexes
- helper functions
- triggers
- row-level security
- reproducible seeds and validation helpers

## What Does Not Belong Here

- undocumented dashboard-only edits
- one-off SQL that cannot be reapplied safely

If another developer or environment needs the change, it should exist here.
