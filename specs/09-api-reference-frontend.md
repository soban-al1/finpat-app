# FinPat Frontend API Reference

This is the frontend-facing API reference for building the app UI against the current backend schema.

It is intentionally practical and aligned with the validated curl flows and the current API client contract.

**Version:** 1.1 — Updated 2026-04-16
Changes: FX-aware exchange rate flow, `dashboard-summary` endpoint, `reset-cycle` surplus behaviour, `due_date` semantics, goal progress.

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
- `amount`, `currency`, `type` (`monthly` or `one-time`)
- `due_date` — stored as **ISO `DATE` (`YYYY-MM-DD`)**, not a free string.
  For monthly obligations the day-of-month is canonical. Do not compute "Due in Nd" on the
  client from this field directly — use `next_due.due_at` + `next_due.days_from_now` from
  the `dashboard-summary` response instead.
- `goal_amount` — non-null for goal-based commitments; progress is returned by `dashboard-summary`
- `is_essential`, `is_completed`, `completed_at`, `has_reminder`

### Remittances
- Table: `remittances`
- List:
  - `GET /rest/v1/remittances?user_id=eq.<user_id>&order=created_at.desc`
- Filter by cycle:
  - `GET /rest/v1/remittances?user_id=eq.<user_id>&date=gte.2026-04-01&date=lt.2026-05-01`
- Create:
  - `POST /rest/v1/remittances`
- Delete:
  - `DELETE /rest/v1/remittances?id=eq.<id>`

Key fields:
- `id`, `user_id`, `center_id`, `obligation_id`
- `date`, `time`
- `amount`, `currency` — amount in the obligation's native currency
- `target_currency` — user's `income_currency` at time of transaction
- `exchange_rate` — rate such that `amount × exchange_rate` = income-currency equivalent
- `purpose`

> **FX note:** `exchange_rate` is set by `toggle-obligation` at the time of completion using
> the live `currency_rates` cache. Do **not** re-derive exchange rates client-side. The server
> is the source of truth for all FX-adjusted totals.

### Savings
- Table: `savings_log` (singular table name)
- List:
  - `GET /rest/v1/savings_log?user_id=eq.<user_id>&order=created_at.desc`
- Filter manual savings for a cycle:
  - `GET /rest/v1/savings_log?user_id=eq.<user_id>&type=eq.manual&date=gte.2026-04-01&date=lt.2026-05-01`
- Create:
  - `POST /rest/v1/savings_log`

Key fields:
- `id`, `user_id`, `date`
- `amount`, `currency`, `type` (`manual` or `surplus`)
- `note`

> `surplus` rows are written automatically by `reset-cycle`. Only `manual` rows should be
> created by the client.

## 5) Edge Functions

### Dashboard summary *(primary Home screen data source)*
`GET /functions/v1/dashboard-summary?cycle=YYYY-MM`

Returns pre-aggregated, FX-adjusted metrics for the given billing cycle. **This replaces all
client-side income/spent/remaining/pressure calculations.**

Query params:
- `cycle` — billing cycle in `YYYY-MM` format (default: current month)
- `responsibility_center_id` — optional UUID, scope to a single center

Response shape:
```json
{
  "success": true,
  "cycle": "2026-04",
  "income": {
    "amount": 8500.00,
    "currency": "USD",
    "frequency": "monthly"
  },
  "spent": 5649.50,
  "remaining": 2850.50,
  "pressure": 66,
  "savings_this_cycle": 250.00,
  "obligations": {
    "total": 12,
    "completed": 8,
    "pending": 4
  },
  "next_due": {
    "obligation_id": "<uuid>",
    "title": "Monthly rent payment",
    "amount": 1500.00,
    "currency": "AED",
    "due_at": "2026-04-30",
    "days_from_now": 14
  },
  "goal_progress": [
    {
      "obligation_id": "<uuid>",
      "title": "Emergency Fund",
      "goal_amount": 5000.00,
      "remitted_amount": 1250.00,
      "progress_pct": 25,
      "currency": "USD"
    }
  ],
  "generated_at": "2026-04-16T09:00:00Z"
}
```

Field notes:
- `income.amount` — normalised to monthly (bi-weekly/weekly converted automatically)
- `spent` — sum of `remittance.amount × remittance.exchange_rate`; always in `income.currency`
- `pressure` — `round(spent / income × 100)`, clamped 0–100
- `next_due.due_at` — ISO date of the next occurrence of the soonest incomplete obligation;
  for monthly obligations the server advances past the current date automatically
- `next_due.days_from_now` — negative means overdue
- `goal_progress` — only obligations where `goal_amount` is non-null; `remitted_amount` is in the obligation's native currency

---

### Exchange rates *(call once per session before toggling obligations)*
`GET /functions/v1/exchange-rates?base=USD`

Warms the `currency_rates` cache used by `toggle-obligation`. Without this call, obligations
completed in non-income currencies will store `exchange_rate = 1.0` (incorrect totals).

Query params:
- `base` — base currency, default `USD`
- `currencies` — comma-separated list to limit response (default: all 17 supported codes)
- `force_refresh=true` — bypass TTL and re-fetch from external API

Response shape:
```json
{
  "success": true,
  "base": "USD",
  "rates": {
    "AED": 3.6725,
    "INR": 83.12,
    "PHP": 56.45,
    "PKR": 278.50,
    "EUR": 0.9198,
    "GBP": 0.7934
  },
  "updated_at": "2026-04-16T08:00:00Z",
  "cache_age_seconds": 120,
  "next_refresh_at": "2026-04-16T09:00:00Z"
}
```

Cache TTL is 1 hour. Rates are fetched from `exchangerate-api.com` (requires `EXCHANGE_RATE_API_KEY` Supabase secret set by the backend team).

---

### Toggle obligation
`POST /functions/v1/toggle-obligation`

```json
{
  "obligation_id": "<id>",
  "is_completed": true
}
```

**When marking complete (`is_completed: true`):**
- Creates a `remittances` row with:
  - `exchange_rate` — looked up from the `currency_rates` cache at call time
  - `target_currency` — user's `income_currency` from profile
- Upserts on `(user_id, obligation_id, date)` — safe to call twice on the same day

**When marking incomplete (`is_completed: false`):**
- Deletes the associated remittance row

Response includes `obligation` (full row) and `remittance` (full row, or `null` when marking incomplete).

> Call `GET /functions/v1/exchange-rates` at least once per session before toggling obligations
> that use a currency different from the user's `income_currency`.

---

### Reset cycle
`POST /functions/v1/reset-cycle`

```json
{
  "cycle_month": "2026-04",
  "responsibility_center_id": "<optional-center-id>"
}
```

Behaviour:
- Computes `surplus = income − spent` where `spent = SUM(remittance.amount × remittance.exchange_rate)` — **FX-adjusted to income_currency**
- If `surplus > 0`: inserts a `savings_log` row (`type = "surplus"`) and returns its `savings_log_id`
- If `surplus ≤ 0`: **no savings row is created**; `savings_log_id` is `null` in the response
- Resets all completed obligations to `is_completed = false`
- Deletes cycle remittances
- **Idempotent** — calling twice with the same `cycle_month` returns the stored audit record

Response shape:
```json
{
  "success": true,
  "surplus": 2850.50,
  "savings_log_id": "<uuid-or-null>",
  "cycle_month": "2026-04",
  "responsibility_center_id": null,
  "total_income": 8500.00,
  "total_spent": 5649.50,
  "obligations_reset": 12,
  "remittances_archived": 8,
  "processed_at": "2026-05-01T00:00:00Z"
}
```

> `savings_log_id` will be `null` when the user spent at or above their income. Handle this
> gracefully — do not show a "surplus saved" confirmation in this case.

---

### Forecast
`GET /functions/v1/forecast?months=6&include_probability=true`

No changes to this endpoint. See `specs/03-api-spec.md` for full response shape.

---

## 6) Recommended Frontend Flow

1. Sign in/signup and store `access_token`, `refresh_token`, `user.id`.
2. **Warm FX cache immediately after sign-in:**
   `GET /functions/v1/exchange-rates?base=USD`
   This ensures `toggle-obligation` stores real rates for any currency pair.
3. Fetch profile, centers, and obligations in parallel for non-Home screens.
4. **For the Home screen:** call `GET /functions/v1/dashboard-summary?cycle=YYYY-MM` as the
   single data source — do not re-compute income/spent/remaining/pressure/next_due client-side.
5. For any write action (create obligation, toggle complete, add savings), call the API and
   update local state optimistically.
6. On `401`, refresh token once and retry the request.
7. On refresh failure, clear session and redirect to login.

### FX-safe obligation toggle sequence

```
1. GET /functions/v1/exchange-rates          ← ensure cache is warm (once per session)
2. POST /functions/v1/toggle-obligation      ← server reads cache, stores real exchange_rate
3. GET /functions/v1/dashboard-summary       ← re-fetch Home; spent/remaining now accurate
```

### Cycle reset confirmation flow

```
1. Show confirmation UI with current surplus from dashboard-summary.remaining
2. POST /functions/v1/reset-cycle { "cycle_month": "YYYY-MM" }
3. If response.savings_log_id != null → show "surplus moved to savings" message
4. If response.savings_log_id == null → show neutral "cycle closed" message (no surplus)
5. GET /functions/v1/dashboard-summary?cycle=<next-month> to refresh Home
```

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

Additional edge function errors to handle:

| code | HTTP | When |
|------|------|------|
| `invalid_cycle` | 400 | `cycle_month` not in `YYYY-MM` format |
| `validation_failed` | 400 | Missing/invalid required field |
| `not_found` | 404 | Obligation not found or not owned by user |
| `internal_error` | 500 | Server-side failure; safe to retry once |