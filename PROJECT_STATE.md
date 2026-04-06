# Project State

## Repository Layout

- `landing-page/`: Next.js App Router marketing site and waitlist flow
- `backend/`: Reserved for future Node.js and Docker services
- `mobile-app/`: Existing Flutter application

## Current Phase

- Repository structure initialized
- Landing page MVP UI assembled
- Waitlist form UI and validation added
- Waitlist API route connected to the live Supabase waitlist table
- Privacy, Terms, and custom 404 pages added
- Backend scaffold reserved

## Landing Page Status

- App Router, TypeScript, and Tailwind scaffold are in place
- Homepage includes navbar, hero, waitlist, features, operator quote, and footer
- Reusable UI components exist for inputs, select fields, buttons, and status messages
- Supabase browser and server helpers are present
- Shared waitlist types and validation helpers are present
- Supabase `public.waitlist` table exists with UUID primary key, `email`, `company_size`, `source`, and `created_at`
- Case-insensitive unique index on waitlist email is configured
- Row Level Security is enabled with public insert allowed and public reads blocked
- Local testing confirms the landing page and waitlist submission flow are working
- Local env setup uses `landing-page/.env.local` with Supabase URL and publishable key
- Landing page image assets and logo files have been added to `landing-page/public/images`
- Navbar uses the supplied `OPS.png` asset as the brand logo
- Hero, map, and operator image files are present in `landing-page/public/images`
- Hero, operator quote, and routing sections now use the supplied image assets directly
- Hero overlay readability and routing-map crop/alignment have been manually tuned against the current assets
- Site metadata icon is now set from the supplied image assets
- Routing section now uses `routing-map.png` as its source asset
- Routing visual has been simplified to a clean image-only presentation
- Root `netlify.toml` is configured to build from the `landing-page` subdirectory with the Next.js Netlify plugin
- Marketing copy no longer positions the product as Edmonton-only and now speaks to field teams worldwide

## Remaining Setup

- Install `landing-page` dependencies
- Run local verification for `npm run build` and linting
