# GitHub Workflows

This folder contains GitHub Actions workflows.

## Current Workflow

- `backend-ci.yml`

## What `backend-ci.yml` Does

- runs only when `backend/**` changes
- installs backend dependencies
- runs lint, build, and tests
- triggers a deploy webhook on pushes to `main`

This narrow scope keeps the backend pipeline from running on unrelated landing-page or mobile changes.
