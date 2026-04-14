# Security Practices (Frontend Repo)

## Secrets Handling

- Never commit `.env.local`, `.env.production`, or any real secret file.
- Commit only `.env.example` with placeholder values.
- Use runtime/CI secret stores for deployment environments.

## Allowed in Frontend

- `VITE_SUPABASE_URL`
- `VITE_SUPABASE_ANON_KEY` (public anon key only)

## Never Expose

- Supabase `service_role` key
- JWT access/refresh tokens in docs or commits
- API keys for third-party paid services

## Logging and Debugging

- Do not log raw tokens in console logs, analytics, or error reports.
- Redact auth headers and token-like strings from client logs.

## PR/Review Checklist

- `.gitignore` includes `.env*` with `.env.example` exception.
- No hardcoded secrets in source, docs, tests, or scripts.
- API examples use placeholders only.

