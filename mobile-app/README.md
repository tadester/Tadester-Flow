# Mobile App

This folder contains the Flutter application workspace for Tadester Ops.

## Current Reality

On this branch, the mobile app is still early and uneven:

- `main.dart` is still the default Flutter counter app
- several directories exist to signal future architecture
- some files are experimental or placeholder-only

So this should be read as an in-progress workspace, not a finished mobile product.

## Main Areas

- `lib/`: Dart source
- `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/`: platform runners
- `test/`: Flutter tests
- `supabase/`: mobile-owned Supabase experiments/config

## Contributor Guidance

If you are trying to understand the future shape of the app, start in `lib/` and read the subfolder docs there first.
