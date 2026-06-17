# Akuko Admin Dashboard (Next.js)

Operations console for Akuko. **This is the preferred admin UI** for new deployments at `akuko/admin-dashboard`.

The older Vite app at [`../admin`](../admin) remains for reference and parity; it was not removed. Migrate bookmarks and deploy targets to this project when ready.

## Setup

1. Copy environment file:

   ```bash
   cp .env.example .env.local
   ```

2. Set Supabase **publishable** credentials (never the service role key in the browser):

   - `NEXT_PUBLIC_SUPABASE_URL`
   - `NEXT_PUBLIC_SUPABASE_ANON_KEY`

3. Ensure your operator user has `profiles.is_admin = true` (and RLS/admin policies from migrations `0007`/`0008` applied).

## Scripts

| Command | Description |
|---------|-------------|
| `npm run dev` | Dev server (default http://localhost:3000) |
| `npm run build` | Production build |
| `npm start` | Run production server after build |

## Features

- Books: upload to Storage (`book-covers`, `book-files`), metadata, approve/reject, featured flag
- Users: list profiles, change `role` (suspend elevated access by demoting to `reader`)
- Subscriptions & Paystack ledger (`subscriptions`, `payment_transactions`)
- Analytics events + revenue placeholders
- Categories CRUD
- Feature flags panel
- Stubs: Authors, Publishers, Royalties, Withdrawals

## Deploy

Build static/server output per your host (Vercel, Node, etc.). Only `NEXT_PUBLIC_*` vars are required at build time for client bundles.

## Related docs

- [`../docs/PHASE4_ADMIN_SUMMARY.md`](../docs/PHASE4_ADMIN_SUMMARY.md)
- [`../docs/RELEASE_READINESS_REPORT.md`](../docs/RELEASE_READINESS_REPORT.md)
