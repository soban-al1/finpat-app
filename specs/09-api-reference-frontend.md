# FinPat Frontend API Reference

This is the frontend-facing API reference for building the app UI against the current backend schema.

It is intentionally practical and aligned with the validated curl flows and the current API client contract.

## 1) Environment

- `VITE_SUPABASE_URL=https://<project-ref>.supabase.co`
- `VITE_SUPABASE_ANON_KEY=<anon-key>`

Security note:
- Use placeholders in docs and examples.
- Never commit real `access_token`, `refresh_token`, service-role keys, or production secrets.

Base paths:
- Auth: `/auth/v1`
- Data (PostgREST): `/rest/v1`
- Edge functions: `/functions/v1`

## 2) Auth Endpoints

### Sign up
`POST /auth/v1/signup`

```json
{
  "email": "user@example.com",
  "password": "Test@123456",
  "data": { "full_name": "User Name" }
}
```

### Sign in (password)
`POST /auth/v1/token?grant_type=password`

```json
{
  "email": "user@example.com",
  "password": "Test@123456"
}
```

Returns:
- `access_token`
- `refresh_token`
- `expires_in`
- `user.id`

### Refresh token
`POST /auth/v1/token?grant_type=refresh_token`

```json
{
  "refresh_token": "<refresh-token>"
}
```

### Sign out
`POST /auth/v1/logout`
Header: `Authorization: Bearer <access_token>`

## 3) Headers and Auth Rules

For all authenticated requests:
- `apikey: <VITE_SUPABASE_ANON_KEY>`
- `Authorization: Bearer <access_token>`
- `Content-Type: application/json`

For create/update requests where response row is needed:
- `Prefer: return=representation`

## 4) Data Tables and Endpoints (Current Schema)

Important: these names/fields reflect the active migration (not older draft naming).

### Profiles
- Table: `profiles`
- Fetch own profile:
  - `GET /rest/v1/profiles?id=eq.<user_id>`
- Update profile:
  - `PATCH /rest/v1/profiles?id=eq.<user_id>`

Key fields:
- `id`, `email`, `name`, `photo_url`
- `onboarded`, `work_location`, `family_location`
- `income_amount`, `income_currency`, `income_frequency`

### Responsibility centers
- Table: `responsibility_centers`
- List:
  - `GET /rest/v1/responsibility_centers?user_id=eq.<user_id>&order=created_at.asc`
- Create:
  - `POST /rest/v1/responsibility_centers`
- Update:
  - `PATCH /rest/v1/responsibility_centers?id=eq.<id>`
- Delete:
  - `DELETE /rest/v1/responsibility_centers?id=eq.<id>`

Key fields:
- `id`, `user_id`, `name`, `icon`, `color`, `is_default`

### Obligations
- Table: `obligations`
- List:
  - `GET /rest/v1/obligations?user_id=eq.<user_id>&order=created_at.desc`
- Create:
  - `POST /rest/v1/obligations`
- Update:
  - `PATCH /rest/v1/obligations?id=eq.<id>`
- Delete:
  - `DELETE /rest/v1/obligations?id=eq.<id>`

Key fields:
- `id`, `user_id`, `center_id`, `title`
- `amount`, `currency`, `type`
- `due_date`, `goal_amount`
- `is_essential`, `is_completed`, `completed_at`, `has_reminder`

### Remittances
- Table: `remittances`
- List:
  - `GET /rest/v1/remittances?user_id=eq.<user_id>&order=created_at.desc`
- Create:
  - `POST /rest/v1/remittances`
- Delete:
  - `DELETE /rest/v1/remittances?id=eq.<id>`

Key fields:
- `id`, `user_id`, `center_id`, `obligation_id`
- `date`, `time`
- `amount`, `currency`, `target_currency`, `exchange_rate`
- `purpose`

### Savings
- Table: `savings_log` (singular table name)
- List:
  - `GET /rest/v1/savings_log?user_id=eq.<user_id>&order=created_at.desc`
- Create:
  - `POST /rest/v1/savings_log`

Key fields:
- `id`, `user_id`, `date`
- `amount`, `currency`, `type` (`manual` or `surplus`)
- `note`

## 5) Edge Functions

### Reset cycle
`POST /functions/v1/reset-cycle`

```json
{
  "cycle_month": "2026-04",
  "responsibility_center_id": "<optional-center-id>"
}
```

### Toggle obligation
`POST /functions/v1/toggle-obligation`

```json
{
  "obligation_id": "<id>",
  "is_completed": true
}
```

### Exchange rates
`GET /functions/v1/exchange-rates?base=USD&currencies=EUR,GBP`

### Forecast
`GET /functions/v1/forecast?months=6&include_probability=true`

## 6) Recommended Frontend Flow

1. Sign in/signup and store `access_token`, `refresh_token`, `user.id`.
2. Fetch profile + centers + obligations + remittances + savings in parallel.
3. Normalize data in app state and render screens.
4. For any write action, call API and update local state optimistically.
5. On `401`, refresh token once and retry request.
6. On refresh failure, clear session and redirect to login.

## 7) Common Error Shapes

You may receive either shape:

```json
{ "code": "invalid_token", "message": "..." }
```

or Supabase auth style:

```json
{ "code": 400, "error_code": "invalid_credentials", "msg": "Invalid login credentials" }
```

Frontend should map both into user-friendly errors.

