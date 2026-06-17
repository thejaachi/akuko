# Live API smoke test

**Base URL:** `https://books.ikikearts.com/wp-json/akuko/v1/`  
**Last checked:** 2026-06-17

## Results

| Endpoint | Method | Expected | Actual | Notes |
|----------|--------|----------|--------|-------|
| `/books` | GET | 200 | **200** | Returns `{"success":true,"data":[...]}` with catalog items. API is reachable. |
| `/auth/login` | POST (no body) | 400 / 401 | **500** | WordPress critical error — empty body not validated before service call. |
| `/auth/login` | POST `{}` | 400 / 401 | **500** | `TypeError`: `AuthenticationService::login()` receives `null` password instead of a validation error. |

## Issue: login validation on live server

When credentials are missing, the plugin should return a REST error (e.g. `invalid_data` / 400), not a PHP `TypeError` (500).

**Suggested fix** (in `akuko-mobile-api`, deploy when ready — do not patch production from this repo session):

- In `Auth_Controller::login`, coerce missing `email` / `password` to empty strings and return `WP_Error` before calling `AuthenticationService::login()`.
- Or add null-safe defaults in `AuthenticationService::login()` and return `invalid_data` when either field is empty.

## How to re-run

```bash
# Books catalog
curl -s -o /dev/null -w "%{http_code}" \
  "https://books.ikikearts.com/wp-json/akuko/v1/books"

# Login without credentials (should be 4xx after fix)
curl -s -w "\n%{http_code}\n" -X POST \
  -H "Content-Type: application/json" \
  -d '{}' \
  "https://books.ikikearts.com/wp-json/akuko/v1/auth/login"
```

PowerShell:

```powershell
Invoke-WebRequest -Uri "https://books.ikikearts.com/wp-json/akuko/v1/books" -UseBasicParsing
Invoke-WebRequest -Uri "https://books.ikikearts.com/wp-json/akuko/v1/auth/login" -Method POST -ContentType "application/json" -Body "{}" -UseBasicParsing
```
