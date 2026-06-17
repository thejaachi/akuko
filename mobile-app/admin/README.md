# Akuko Admin Dashboard

Phase 1 internal operations console for the Akuko catalogue. Separate from the Flutter mobile app; lives only under `akuko/admin/`.

## Stack

- **Vite 8** + **React 19** + **TypeScript**
- **React Router 7** for client-side routes
- **Tailwind CSS 4** (Material-inspired admin UI)
- **@supabase/supabase-js** (anon key only — no service role in the browser)

## Prerequisites

- Node.js 20+
- Supabase project with migrations **0001–0008** applied (`0007_improvements.sql` + `0008_ecosystem.sql` are required for moderation and feature flags)
- At least one user with `profiles.is_admin = true` (see [SUPABASE_SETUP.md](../docs/SUPABASE_SETUP.md))

## Install & run

```bash
cd akuko/admin
cp .env.example .env.local
# Fill VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY from Dashboard → Project Settings → API
npm install
npm run dev
```

Open <http://localhost:5173> (Vite default).

See [DEPLOY_VALIDATION.md](./DEPLOY_VALIDATION.md) for a full deploy checklist.

## Environment variables

| Variable | Description |
|----------|-------------|
| `VITE_SUPABASE_URL` | Supabase project URL |
| `VITE_SUPABASE_ANON_KEY` | Supabase **anon/public** key (never the service role) |

Copy `.env.example` → `.env.local`. `.env.local` is git-ignored.

## Admin access

1. User signs in with email/password via Supabase Auth.
2. App loads `profiles.is_admin` for `auth.uid()`.
3. If `is_admin` is not `true`, the session is cleared and login shows an access-denied message.
4. Protected routes require an active session **and** `is_admin`.

RLS enforces the same on the server: catalogue writes and Storage uploads use policies gated by `public.is_admin()`.

Promote an admin (SQL editor, service role):

```sql
update public.profiles
set is_admin = true, role = 'admin'
where id = '<auth-user-uuid>';
```

## Book workflow (0008)

| Step | `books.status` | Notes |
|------|----------------|-------|
| Admin upload (default) | `pending_review` | Sets `uploaded_by` to current admin |
| Fast-publish toggle | `published` | Sets `approved_by`, `approved_at` |
| Approve on list | `published` | Clears `rejection_reason` |
| Reject (modal) | `rejected` | Requires `rejection_reason` |
| Re-queue / Archive | `pending_review` / `archived` | Optional moderation actions |

Public catalogue should filter `status = 'published'` (see `published_books` view).

## Author moderation (no `authors.status`)

Migration **0008** adds `profiles.role` and `profiles.author_id`, not a status column on `authors`.

| Action | Effect |
|--------|--------|
| **Approve** | `profiles.role = 'author'` for rows with matching `author_id` |
| **Suspend** | `profiles.role = 'reader'`, `author_id = null` |
| **Pending queue** | `profiles` where `role = 'reader'` and `author_id` is set |

## Feature flags

Settings page reads/writes `public.feature_flags` (`key`, `enabled`, `description`, `phase`, `updated_at`). See [FEATURE_FLAGS.md](../docs/FEATURE_FLAGS.md).

Phase 4 keys `payouts` and `royalties` show a warning when disabled — keep off in production until payouts are ready.

## Scripts

| Command | Purpose |
|---------|---------|
| `npm run dev` | Local dev server |
| `npm run build` | Production build → `dist/` |
| `npm run preview` | Preview production build |
| `npm run lint` | ESLint |

## Pages (0008-wired)

| Route | Data |
|-------|------|
| `/books` | `books.status`, workflow actions |
| `/books/upload` | `pending_review` default, optional fast-publish |
| `/authors` | `authors` + `profiles.role` / `author_id` |
| `/publishers` | `publishers.status`, `publisher_members` count |
| `/payments` | `payment_transactions` + `subscriptions` (RLS-limited) |
| `/analytics` | `analytics_events` (last 50) |
| `/settings` | `feature_flags` CRUD |

## Security

- Never commit `.env.local` or real API keys.
- Do not embed `SUPABASE_SERVICE_ROLE_KEY` in this app.
- Keep migration and edge-function changes in `akuko/supabase/` (not here).
