# finpat_mobile

A new Flutter project.

## Getting Started

This project is a starting point for a Flutter application.

A few resources to get you started if this is your first Flutter project:

- [Learn Flutter](https://docs.flutter.dev/get-started/learn-flutter)
- [Write your first Flutter app](https://docs.flutter.dev/get-started/codelab)
- [Flutter learning resources](https://docs.flutter.dev/reference/learning-resources)

For help getting started with Flutter development, view the
[online documentation](https://docs.flutter.dev/), which offers tutorials,
samples, guidance on mobile development, and a full API reference.

## Supabase production config (Android release)

1. Copy `.env.prod.json.example` to `.env.prod.json`.
2. Set `SUPABASE_URL` and `SUPABASE_ANON_KEY` in `.env.prod.json`.
3. Build with compile-time defines:

```bash
flutter build appbundle --release --dart-define-from-file=.env.prod.json
```

Use only the Supabase anon key in the app. Never place `service_role` keys in
mobile builds.
