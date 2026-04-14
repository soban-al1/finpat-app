# FinPat Mobile Frontend Start Guide

This file is the mobile frontend implementation entry point for AI-assisted development.

Use this in the FE repo as the primary context before generating screens, state, API clients, and flows.

## 1) Objective

Build the FinPat native mobile app with Flutter that:
- authenticates users with Supabase Auth,
- manages responsibility centers, obligations, remittances, and savings,
- supports dashboard and forecast experiences,
- follows the design and screen specs in this folder.
- ships Android first, then iOS.

## 2) Source of Truth

Frontend implementation should use:
- `specs/01-design-system.md`
- `specs/05-screens-auth-onboarding.md`
- `specs/06-screens-dashboard.md`
- `specs/07-screens-centers.md`
- `specs/08-screens-remittance-savings-forecast.md`
- `specs/09-api-reference-frontend.md` (API contract for FE)

## 3) Environment and Runtime

Runtime target:
- Flutter native mobile app (`Android` first milestone, `iOS` follow-up milestone).

Required env vars:
- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`

Expected setup:
1. install Flutter SDK and platform toolchains (Android now, iOS later)
2. `flutter pub get`
3. create runtime config for both vars (for example via `--dart-define` or secure config handling)
4. run Android target first (`flutter run` on Android emulator/device)
5. add/validate iOS target in the follow-up phase

## 4) Frontend Architecture Requirements

- Keep API access in a dedicated data layer (for example repository/service clients).
- Keep screen widgets mostly presentation-focused.
- Use a central session/auth state:
  - `access_token`
  - `refresh_token`
  - `user.id`
- On app bootstrap:
  - restore session
  - fetch profile and core entities
  - render app shell only when initial hydration completes

## 5) Core User Flows

### Auth
- Sign up with email/password.
- Sign in with email/password.
- Persist and refresh session token.
- Logout should clear local session state and cached entities.

### Onboarding
- Capture work location, family location, income amount/currency/frequency.
- Persist to `profiles` fields:
  - `onboarded`
  - `work_location`
  - `family_location`
  - `income_amount`
  - `income_currency`
  - `income_frequency`

### Data Management
- Centers CRUD (`responsibility_centers`)
- Obligations CRUD (`obligations`)
- Completion toggle for obligations (`is_completed`, `completed_at`)
- Remittance logging (`remittances`)
- Savings logging (`savings_log`)

### Insights
- Dashboard summary from profile + obligations + remittances + savings.
- Forecast and exchange-rates via edge functions when available.

## 6) API and Schema Notes (Critical)

- Use `specs/09-api-reference-frontend.md` for endpoint/field names.
- Do not assume older draft naming from early docs.
- Current validated names include:
  - `center_id` (not `responsibility_center_id`) in obligations/remittances
  - `savings_log` endpoint/table (singular)
  - profile fields like `name`, `photo_url`, `work_location`, `income_amount`

## 7) Error Handling Expectations

- Parse both standard and Supabase auth error shapes.
- Handle:
  - `invalid_credentials`
  - `invalid_token`
  - rate-limit responses (`429`)
- Show actionable UI messages; avoid generic `Request failed`.

## 8) Performance and UX Baseline

- Hydrate core data in parallel after login.
- Use optimistic updates for create/update when safe.
- Reconcile state with server response rows (`Prefer: return=representation`).
- Keep loading and empty states on all data screens.

## 9) Definition of Done for FE Milestones

For each screen/feature:
1. UI matches spec behavior.
2. Reads/writes data from real API.
3. Handles loading, empty, error states.
4. Auth/session edge cases validated.
5. No Dart analyzer errors.

