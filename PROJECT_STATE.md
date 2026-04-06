# Project State

## Repository Layout

- `landing-page/`: Next.js App Router marketing site and waitlist flow
- `backend/`: Reserved for future Node.js and Docker services
- `mobile-app/`: Existing Flutter application

## Current Phase

- Repository structure initialized
- Landing page MVP UI assembled
- Waitlist form UI and validation added
- Waitlist API route scaffolded with Supabase integration hooks
- Privacy, Terms, and custom 404 pages added
- Backend scaffold reserved

## Landing Page Status

- App Router, TypeScript, and Tailwind scaffold are in place
- Homepage includes navbar, hero, waitlist, features, operator quote, and footer
- Reusable UI components exist for inputs, select fields, buttons, and status messages
- Supabase browser and server helpers are present
- Shared waitlist types and validation helpers are present

## Remaining Setup

- Install `landing-page` dependencies
- Add real Supabase environment values in local `.env`
- Create the `waitlist_submissions` table and duplicate email constraint in Supabase
- Run local verification for build, lint, and form submission behavior
