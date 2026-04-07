# Tadester Ops Monorepo

This repository contains the three main product surfaces for Tadester Ops:

- `landing-page/`: public marketing site and waitlist flow
- `backend/`: Node.js API and backend-owned Supabase workspace
- `mobile-app/`: Flutter client workspace

It also contains root-level operational files:

- `PROJECT_STATE.md`: rolling implementation snapshot
- `docker-compose.yml`: local backend + Postgres composition
- `netlify.toml`: Netlify config for the landing page
- `.github/`: CI/CD workflows

## How To Navigate The Repo

This repo is organized by product surface instead of by language.

- Work on marketing or waitlist UX in `landing-page/`
- Work on APIs, containers, or schema in `backend/`
- Work on Flutter/mobile runtime concerns in `mobile-app/`

Each major folder now includes documentation to explain what it owns.

## Current Maturity By Area

- `landing-page/` is the most complete user-facing area
- `backend/` is scaffolded and deployable, with health, Docker, CI, and database workspace
- `mobile-app/` on this branch is still early-stage and contains default Flutter scaffold code plus placeholder/experimental folders

That means some folders describe future intent as well as current reality.

## Root Folder Guide

### `.github/`
GitHub Actions workflows and repository automation.

### `.vscode/`
Editor-local configuration. Helpful for contributors, not runtime code.

### `backend/`
Backend service, tests, Docker setup, and Supabase migrations.

### `landing-page/`
Next.js landing page and waitlist frontend.

### `mobile-app/`
Flutter application workspace and platform runners.

## Generated Folders

The following folders are generated or environment-specific and are not the primary places to edit by hand:

- `.git/`
- `node_modules/`
- `.next/`
- `dist/`
- `build/`
- `.dart_tool/`
