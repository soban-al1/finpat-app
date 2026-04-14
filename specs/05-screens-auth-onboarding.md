# Auth and Onboarding Screens

## 1. Scope

Defines frontend behavior for:
- Login
- Signup
- Session restoration
- Multi-step onboarding

## 2. Auth Screen Requirements

### Login
- Inputs:
  - Email
  - Password
- Action:
  - `POST /auth/v1/token?grant_type=password`
- Success:
  - Store session tokens
  - Fetch initial user data
  - Route to onboarding or dashboard
- Failure:
  - Show API message (e.g. `Invalid login credentials`)

### Signup
- Inputs:
  - Full name
  - Email
  - Password
- Action:
  - `POST /auth/v1/signup`
- Behavior:
  - If session returned, continue as logged in
  - If provider throttle/confirmation issue, show explicit guidance

### Session restore
- On app launch:
  - Load saved session
  - Attempt profile fetch
  - If token expired, refresh
  - If refresh fails, force logout

## 3. Onboarding Flow

### Step 1: Context
- Fields:
  - `work_location`
  - `family_location`

### Step 2: Income
- Fields:
  - `income_amount`
  - `income_currency`
  - `income_frequency` (`monthly` | `bi-weekly` | `weekly`)

### Step 3: Responsibility setup
- Show default centers + allow custom center creation.
- Save selected/setup centers to `responsibility_centers`.

### Complete onboarding
- Update profile:
  - `onboarded = true`
- Route user to dashboard.

## 4. Validation

- Email format required.
- Password minimum length required.
- Income amount must be non-negative.
- Required onboarding fields cannot be empty on final submit.

## 5. UX States

- Loading: disable submit buttons while request in flight.
- Error: inline message under form.
- Success: clear transition to next screen.


