# FinPat Mobile App

Flutter native mobile app scaffold for FinPat.

Delivery sequence:
- Android first
- iOS after Android milestone is stable

## Project Structure

- `mobile_app/` - Flutter app scaffold and starter features
- `specs/` - product/design/API references used to implement screens and flows
- `src/` - legacy web prototype (kept for reference while migrating)

## Run (Android first)

1. Install Flutter SDK and Android toolchain.
2. From `mobile_app/`, run:
   - `flutter pub get`
   - `flutter run --dart-define=SUPABASE_URL=... --dart-define=SUPABASE_ANON_KEY=...`

## Current Starter Features

- Supabase bootstrap using Dart defines
- Auth gate based on Supabase session state
- Sign in / sign up starter screen
- Dashboard placeholder with sign-out

## Notes

- Never commit real secrets/tokens.
- Use `specs/start.md` as implementation entry point.
