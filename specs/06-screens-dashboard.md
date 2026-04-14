# Dashboard Screen Spec

## 1. Purpose

Provide a clear monthly snapshot:
- income
- spent
- remaining
- pressure/risk
- active commitments

## 2. Data Sources

- `profiles` for income and onboarding context.
- `obligations` for commitments.
- `remittances` for spending logs.
- `savings_log` for manual and surplus savings.

## 3. KPI Cards

Required:
- Total Monthly Income
- Total Spent
- Remaining Balance
- Pressure Indicator (spent/income ratio)

Optional:
- Due next obligation
- Commitments completed vs total

## 4. Pressure Indicator Rules

- `healthy`: remaining >= 20% of income
- `warning`: remaining between 5% and 20%
- `critical`: remaining < 5% or negative

## 5. Actions

- Toggle obligation completion (updates `is_completed`, `completed_at`)
- Add manual savings (create `savings_log` row)
- Reset cycle (edge function when available)

## 6. States

- Loading skeleton for first load
- Empty state if no obligations
- Inline warnings for API errors

## 7. Performance

- Fetch dashboard entities in parallel.
- Cache data in memory state and refetch on mutation completion.


