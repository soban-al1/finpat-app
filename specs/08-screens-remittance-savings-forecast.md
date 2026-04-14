# Remittance, Savings, and Forecast Screens

## 1. Remittance Screen

### Purpose
- Track spending transactions.
- Link ad-hoc or obligation-based remittances.

### Endpoints
- List: `GET /rest/v1/remittances?user_id=eq.<id>&order=created_at.desc`
- Create: `POST /rest/v1/remittances`
- Delete: `DELETE /rest/v1/remittances?id=eq.<id>`

### Required create fields
- `user_id`
- `center_id`
- `date`
- `amount`
- `currency`
- `target_currency`
- `exchange_rate`

Optional:
- `obligation_id`
- `time`
- `purpose`

## 2. Savings Screen

### Purpose
- Show savings timeline and totals.

### Endpoints
- List: `GET /rest/v1/savings_log?user_id=eq.<id>&order=created_at.desc`
- Create: `POST /rest/v1/savings_log`

### Required create fields
- `user_id`
- `date`
- `amount`
- `currency`
- `type` (`manual` or `surplus`)

Optional:
- `note`

## 3. Forecast Screen

### Purpose
- Show projected financial health over upcoming months.

### Endpoint
- `GET /functions/v1/forecast?months=6&include_probability=true`

### UI expectations
- month-by-month chart
- status labels (`healthy`, `warning`, `critical`)
- summary stats (min/avg/max remaining)

## 4. Exchange Rates (Optional Utility)

- `GET /functions/v1/exchange-rates?base=USD`
- Use for conversion hints; do not block core UX if unavailable.

## 5. Error Handling

- Show explicit API messages for:
  - auth/token issues
  - validation errors
  - function unavailability
- Keep read-only fallback UI if forecast/exchange functions fail.


