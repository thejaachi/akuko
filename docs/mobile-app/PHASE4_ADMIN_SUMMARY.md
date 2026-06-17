# Phase 4 — Admin Dashboard Summary

**Date:** 2026-06-04  
**Preferred path:** `akuko/admin-dashboard` (Next.js 14 App Router)  
**Legacy path retained:** `akuko/admin` (Vite + React) — not deleted

## Decision

Per user spec, created **new** Next.js 14 console at `admin-dashboard/`, reusing service patterns from `admin/` (Supabase JS, books/users/payments/analytics).

## Stack

- Next.js 14.2 + App Router + TypeScript
- Tailwind CSS
- `@supabase/supabase-js` + `lucide-react`

## MVP routes

| Route | Feature |
|-------|---------|
| `/login` | Email/password; requires `profiles.is_admin` |
| `/` | Dashboard stats |
| `/books` | List, approve/reject, toggle featured |
| `/books/upload` | EPUB/PDF + cover to Storage |
| `/users` | List profiles; change `role` |
| `/subscriptions` | `subscriptions` + `payment_transactions` |
| `/analytics` | `analytics_events` + revenue placeholders |
| `/categories` | CRUD |
| `/feature-flags` | Toggle `feature_flags` |
| `/authors`, `/publishers`, `/royalties`, `/withdrawals` | Stubs |

## Env

`admin-dashboard/.env.example`:

- `NEXT_PUBLIC_SUPABASE_URL`
- `NEXT_PUBLIC_SUPABASE_ANON_KEY`

## Build verification

```bash
cd akuko/admin-dashboard
npm install
npm run build
```

**Result:** `npm run build` succeeded (Next.js 14.2.35).

## Local dev

```bash
cd akuko/admin-dashboard
cp .env.example .env.local
npm run dev
```

Open http://localhost:3000 — sign in with an admin profile.

## Migration note

See `admin-dashboard/README.md` for relationship to `akuko/admin` (Vite).
