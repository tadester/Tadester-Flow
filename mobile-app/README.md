# Mobile App

This is the Flutter operations app for Tadester Ops. It supports organization-aware authentication, role-based workspaces, admin operations screens, worker job views, route maps, and live location tracking controls.

## Main Capabilities

- Supabase sign in, sign up, password reset, and session persistence
- organization-aware account creation
- role-based routing for management and workers
- admin pages for overview, jobs, workers, and settings
- worker pages for jobs, route map, and settings
- location permission flow and tracking sync hooks

## Setup

Create `mobile-app/.env`:

```env
SUPABASE_URL=your_supabase_project_url
SUPABASE_ANON_KEY=your_anon_key
BACKEND_API_URL=https://tadester-ops.onrender.com
GOOGLE_MAPS_API_KEY=your_google_maps_key
```

Install dependencies:

```bash
cd mobile-app
flutter pub get
```

## Run

```bash
flutter run
```

## iOS

After Podfile, permission, or native plugin changes:

```bash
flutter clean
flutter pub get
cd ios
pod install
cd ..
flutter run
```

## macOS

After entitlement or plugin changes:

```bash
flutter clean
flutter pub get
flutter run -d macos
```

## Tester Login Details

### Management

- `demo.north.admin@tadesterops.dev` / `password123`
- `demo.north.dispatcher@tadesterops.dev` / `password123`
- `demo.prairie.admin@tadesterops.dev` / `password123`
- `demo.prairie.operator@tadesterops.dev` / `password123`

### Workers

- `demo.north.worker.one@tadesterops.dev` / `password123`
- `demo.north.worker.two@tadesterops.dev` / `password123`
- `demo.prairie.worker.one@tadesterops.dev` / `password123`
- `demo.prairie.worker.two@tadesterops.dev` / `password123`

## Testing Checklist

### Admin

- sign in as `demo.north.admin@tadesterops.dev`
- verify overview, jobs, workers, and settings pages load
- create and assign work

### Worker

- sign in as `demo.north.worker.one@tadesterops.dev`
- open job detail from the jobs page
- open route map
- open settings and enable live tracking

## Notes

- Worker active/inactive is based on whether a fresh ping has arrived within 10 minutes.
- On iPhone, the app can only open the Tadester Ops settings page; you still tap `Location` there manually.
- On macOS, outbound network access is enabled through the app entitlements for Debug, Profile, and Release builds. Use a clean rebuild after entitlement changes so the desktop app picks them up.
