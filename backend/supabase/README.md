# Backend Supabase

This folder is the backend-owned Supabase workspace for the operational product schema.

## Purpose

It keeps database ownership with the backend instead of scattering schema changes across the landing page or mobile app.

## What Lives Here

- `config.toml`: Supabase CLI project configuration
- `seed.sql`: seed entrypoint
- `migrations/`: ordered SQL history

## Why It Matters

This folder is the source of truth for operational data such as:

- organizations
- profiles
- locations
- jobs
- assignments
- worker activity
- geofence events

The landing-page waitlist remains separate from this backend-owned operational schema history.
