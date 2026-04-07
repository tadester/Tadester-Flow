# Landing Page App Router

This folder contains the Next.js App Router structure.

## Current Responsibilities

- define route entrypoints
- provide the root HTML shell
- assemble the homepage
- host legal pages
- expose the waitlist API route

## Important Files

- `layout.tsx`: document shell and metadata
- `page.tsx`: homepage composition
- `globals.css`: global styles
- `privacy/page.tsx`: privacy page
- `terms/page.tsx`: terms page
- `not-found.tsx`: custom 404 page

## Rule Of Thumb

Keep page orchestration here. Shared UI belongs in `components/`.
