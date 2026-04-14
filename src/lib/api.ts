type ApiErrorCode =
  | 'validation_failed'
  | 'invalid_credentials'
  | 'invalid_token'
  | 'unauthorized'
  | 'not_found'
  | 'conflict'
  | 'constraint_violation'
  | 'unprocessable_entity'
  | 'rate_limit_exceeded'
  | 'internal_error'
  | 'service_unavailable'
  | 'unknown_error';

export interface ApiErrorPayload {
  code: ApiErrorCode;
  message: string;
  details?: Record<string, unknown>;
}

export class ApiError extends Error {
  readonly status: number;
  readonly code: ApiErrorCode;
  readonly details?: Record<string, unknown>;

  constructor(status: number, payload: Partial<ApiErrorPayload> & { message: string }) {
    super(payload.message);
    this.name = 'ApiError';
    this.status = status;
    this.code = payload.code ?? 'unknown_error';
    this.details = payload.details;
  }
}

type HttpMethod = 'GET' | 'POST' | 'PATCH' | 'PUT' | 'DELETE';

interface RequestOptions<TBody = unknown> {
  method?: HttpMethod;
  accessToken?: string;
  query?: Record<string, string | number | boolean | undefined>;
  headers?: Record<string, string>;
  body?: TBody;
}

interface AuthSession {
  access_token: string;
  refresh_token: string;
  expires_in: number;
  token_type: 'bearer';
  user?: {
    id: string;
    email: string;
  };
}

export interface AuthUser {
  id: string;
  email: string;
  user_metadata?: Record<string, unknown>;
  app_metadata?: Record<string, unknown>;
  created_at?: string;
  updated_at?: string;
}

export interface AuthSignupResponse {
  user: AuthUser;
  session: AuthSession | null;
}

export interface Profile {
  id: string;
  email: string;
  name: string | null;
  photo_url: string | null;
  onboarded: boolean;
  work_location: string | null;
  family_location: string | null;
  income_amount: number | null;
  income_currency: string;
  income_frequency: 'monthly' | 'bi-weekly' | 'weekly';
  created_at: string;
  updated_at: string;
}

export interface ResponsibilityCenter {
  id: string;
  user_id: string;
  name: string;
  icon: string;
  color: string;
  is_default: boolean;
  created_at: string;
  updated_at: string;
}

export interface Obligation {
  id: string;
  user_id: string;
  center_id: string;
  title: string;
  amount: number;
  currency: string;
  type: 'monthly' | 'one-time';
  due_date: string | null;
  goal_amount: number | null;
  is_essential: boolean;
  is_completed: boolean;
  completed_at: string | null;
  has_reminder: boolean;
  created_at: string;
  updated_at: string;
}

export interface Remittance {
  id: string;
  user_id: string;
  center_id: string;
  obligation_id: string | null;
  date: string;
  time: string | null;
  amount: number;
  currency: string;
  target_currency: string;
  exchange_rate: number;
  purpose: string | null;
  created_at: string;
  updated_at: string;
}

export interface SavingsLog {
  id: string;
  user_id: string;
  date: string;
  amount: number;
  currency: string;
  type: 'surplus' | 'manual';
  note: string | null;
  created_at: string;
  updated_at: string;
}

export interface ToggleObligationResponse {
  success: boolean;
  obligation: Obligation;
  remittance: Remittance | null;
}

export interface ResetCycleResponse {
  success: boolean;
  surplus: number;
  savings_log_id: string;
  cycle_month: string;
  responsibility_center_id: string | null;
  total_income: number;
  total_spent: number;
  obligations_reset: number;
  remittances_archived: number;
  processed_at: string;
}

export interface ExchangeRatesResponse {
  success: boolean;
  base: string;
  rates: Record<string, number>;
  updated_at: string;
  cache_age_seconds: number;
  next_refresh_at: string;
}

interface ForecastMonth {
  month: string;
  income: number;
  recurring_commitments: number;
  remaining: number;
  status: 'healthy' | 'warning' | 'critical';
  obligations_count: number;
  has_risk: boolean;
}

interface ForecastSummary {
  total_months: number;
  healthy_count: number;
  warning_count: number;
  critical_count: number;
  average_remaining: number;
  min_remaining: number;
  max_remaining: number;
}

export interface ForecastResponse {
  success: boolean;
  forecast: {
    months: ForecastMonth[];
    summary: ForecastSummary;
    forecast_generated_at: string;
  };
}

const SUPABASE_URL = import.meta.env.VITE_SUPABASE_URL;
const SUPABASE_ANON_KEY = import.meta.env.VITE_SUPABASE_ANON_KEY;

if (!SUPABASE_URL || !SUPABASE_ANON_KEY) {
  throw new Error('Missing `VITE_SUPABASE_URL` or `VITE_SUPABASE_ANON_KEY` environment variable.');
}

const REST_BASE = `${SUPABASE_URL}/rest/v1`;
const AUTH_BASE = `${SUPABASE_URL}/auth/v1`;
const FUNCTIONS_BASE = `${SUPABASE_URL}/functions/v1`;

function buildUrl(base: string, path: string, query?: RequestOptions['query']): string {
  const normalizedPath = path.startsWith('/') ? path : `/${path}`;
  const url = new URL(`${base}${normalizedPath}`);

  if (query) {
    Object.entries(query).forEach(([key, value]) => {
      if (value === undefined) return;
      url.searchParams.set(key, String(value));
    });
  }

  return url.toString();
}

async function parseResponse<T>(response: Response): Promise<T> {
  if (response.status === 204) {
    return undefined as T;
  }

  const text = await response.text();
  const data = text ? (JSON.parse(text) as unknown) : undefined;

  if (!response.ok) {
    const raw = (data ?? {}) as Record<string, unknown>;
    const payload = raw as Partial<ApiErrorPayload>;
    const normalizedMessage =
      (typeof payload.message === 'string' && payload.message) ||
      (typeof raw.msg === 'string' && raw.msg) ||
      response.statusText ||
      'Request failed';
    const normalizedCode =
      (typeof payload.code === 'string' && payload.code) ||
      (typeof raw.error_code === 'string' && raw.error_code) ||
      'unknown_error';
    throw new ApiError(response.status, {
      message: normalizedMessage,
      code: normalizedCode as ApiErrorCode,
      details: payload.details,
    });
  }

  return data as T;
}

async function request<TResponse, TBody = unknown>(
  base: string,
  path: string,
  options: RequestOptions<TBody> = {},
): Promise<TResponse> {
  const { method = 'GET', accessToken, query, headers, body } = options;
  const url = buildUrl(base, path, query);

  const response = await fetch(url, {
    method,
    headers: {
      apikey: SUPABASE_ANON_KEY,
      Authorization: accessToken ? `Bearer ${accessToken}` : `Bearer ${SUPABASE_ANON_KEY}`,
      'Content-Type': 'application/json',
      ...headers,
    },
    body: body === undefined ? undefined : JSON.stringify(body),
  });

  return parseResponse<TResponse>(response);
}

export const authApi = {
  signUp(payload: { email: string; password: string; data?: Record<string, unknown> }) {
    return request<AuthSignupResponse, typeof payload>(AUTH_BASE, '/signup', {
      method: 'POST',
      body: payload,
    });
  },

  signInWithPassword(payload: { email: string; password: string }) {
    return request<AuthSession, typeof payload>(AUTH_BASE, '/token', {
      method: 'POST',
      query: { grant_type: 'password' },
      body: payload,
    });
  },

  refreshSession(payload: { refresh_token: string }) {
    return request<AuthSession, typeof payload>(AUTH_BASE, '/token', {
      method: 'POST',
      query: { grant_type: 'refresh_token' },
      body: payload,
    });
  },

  signOut(accessToken: string) {
    return request<void>(AUTH_BASE, '/logout', {
      method: 'POST',
      accessToken,
    });
  },

  getCurrentUser(accessToken: string) {
    return request<AuthUser>(AUTH_BASE, '/user', {
      method: 'GET',
      accessToken,
    });
  },

  updateCurrentUser(
    accessToken: string,
    payload: { email?: string; password?: string; data?: Record<string, unknown> },
  ) {
    return request<AuthUser, typeof payload>(AUTH_BASE, '/user', {
      method: 'PUT',
      accessToken,
      body: payload,
    });
  },
};

export const profilesApi = {
  getCurrent(accessToken: string, userId: string) {
    return request<Profile[]>(REST_BASE, '/profiles', {
      method: 'GET',
      accessToken,
      query: { id: `eq.${userId}` },
      headers: { Prefer: 'return=representation' },
    });
  },

  update(accessToken: string, userId: string, patch: Partial<Omit<Profile, 'id' | 'email' | 'created_at' | 'updated_at'>>) {
    return request<Profile[], typeof patch>(REST_BASE, '/profiles', {
      method: 'PATCH',
      accessToken,
      query: { id: `eq.${userId}` },
      headers: { Prefer: 'return=representation' },
      body: patch,
    });
  },
};

export const centersApi = {
  list(accessToken: string, userId: string, options?: { order?: string }) {
    return request<ResponsibilityCenter[]>(REST_BASE, '/responsibility_centers', {
      method: 'GET',
      accessToken,
      query: {
        user_id: `eq.${userId}`,
        order: options?.order ?? 'created_at.asc',
      },
    });
  },

  create(accessToken: string, payload: Omit<ResponsibilityCenter, 'id' | 'created_at' | 'updated_at'>) {
    return request<ResponsibilityCenter[], typeof payload>(REST_BASE, '/responsibility_centers', {
      method: 'POST',
      accessToken,
      headers: { Prefer: 'return=representation' },
      body: payload,
    });
  },

  update(
    accessToken: string,
    id: string,
    patch: Partial<Omit<ResponsibilityCenter, 'id' | 'user_id' | 'created_at' | 'updated_at'>>,
  ) {
    return request<ResponsibilityCenter[], typeof patch>(REST_BASE, '/responsibility_centers', {
      method: 'PATCH',
      accessToken,
      query: { id: `eq.${id}` },
      headers: { Prefer: 'return=representation' },
      body: patch,
    });
  },

  remove(accessToken: string, id: string) {
    return request<void>(REST_BASE, '/responsibility_centers', {
      method: 'DELETE',
      accessToken,
      query: { id: `eq.${id}` },
    });
  },
};

export const obligationsApi = {
  list(accessToken: string, userId: string, query?: Record<string, string>) {
    return request<Obligation[]>(REST_BASE, '/obligations', {
      method: 'GET',
      accessToken,
      query: {
        user_id: `eq.${userId}`,
        ...query,
      },
    });
  },

  create(accessToken: string, payload: Omit<Obligation, 'id' | 'created_at' | 'updated_at'>) {
    return request<Obligation[], typeof payload>(REST_BASE, '/obligations', {
      method: 'POST',
      accessToken,
      headers: { Prefer: 'return=representation' },
      body: payload,
    });
  },

  update(
    accessToken: string,
    id: string,
    patch: Partial<Omit<Obligation, 'id' | 'user_id' | 'created_at' | 'updated_at'>>,
  ) {
    return request<Obligation[], typeof patch>(REST_BASE, '/obligations', {
      method: 'PATCH',
      accessToken,
      query: { id: `eq.${id}` },
      headers: { Prefer: 'return=representation' },
      body: patch,
    });
  },

  remove(accessToken: string, id: string) {
    return request<void>(REST_BASE, '/obligations', {
      method: 'DELETE',
      accessToken,
      query: { id: `eq.${id}` },
    });
  },
};

export const remittancesApi = {
  list(accessToken: string, userId: string, query?: Record<string, string>) {
    return request<Remittance[]>(REST_BASE, '/remittances', {
      method: 'GET',
      accessToken,
      query: {
        user_id: `eq.${userId}`,
        ...query,
      },
    });
  },

  create(accessToken: string, payload: Omit<Remittance, 'id' | 'created_at' | 'updated_at'>) {
    return request<Remittance[], typeof payload>(REST_BASE, '/remittances', {
      method: 'POST',
      accessToken,
      headers: { Prefer: 'return=representation' },
      body: payload,
    });
  },

  remove(accessToken: string, id: string) {
    return request<void>(REST_BASE, '/remittances', {
      method: 'DELETE',
      accessToken,
      query: { id: `eq.${id}` },
    });
  },
};

export const savingsApi = {
  list(accessToken: string, userId: string, query?: Record<string, string>) {
    return request<SavingsLog[]>(REST_BASE, '/savings_log', {
      method: 'GET',
      accessToken,
      query: {
        user_id: `eq.${userId}`,
        ...query,
      },
    });
  },

  create(accessToken: string, payload: Omit<SavingsLog, 'id' | 'created_at' | 'updated_at'>) {
    return request<SavingsLog[], typeof payload>(REST_BASE, '/savings_log', {
      method: 'POST',
      accessToken,
      headers: { Prefer: 'return=representation' },
      body: payload,
    });
  },
};

export const edgeFunctionsApi = {
  resetCycle(
    accessToken: string,
    payload: { cycle_month: string; responsibility_center_id?: string },
  ) {
    return request<ResetCycleResponse, typeof payload>(FUNCTIONS_BASE, '/reset-cycle', {
      method: 'POST',
      accessToken,
      body: payload,
    });
  },

  toggleObligation(
    accessToken: string,
    payload: { obligation_id: string; is_completed: boolean },
  ) {
    return request<ToggleObligationResponse, typeof payload>(FUNCTIONS_BASE, '/toggle-obligation', {
      method: 'POST',
      accessToken,
      body: payload,
    });
  },

  getExchangeRates(
    accessToken: string,
    query?: { base?: string; currencies?: string; force_refresh?: boolean },
  ) {
    return request<ExchangeRatesResponse>(FUNCTIONS_BASE, '/exchange-rates', {
      method: 'GET',
      accessToken,
      query,
    });
  },

  getForecast(
    accessToken: string,
    query?: { months?: number; include_probability?: boolean; responsibility_center_id?: string },
  ) {
    return request<ForecastResponse>(FUNCTIONS_BASE, '/forecast', {
      method: 'GET',
      accessToken,
      query,
    });
  },
};

