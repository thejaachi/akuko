# Admin dashboard — deploy validation

Run these steps on **your** machine with your Supabase project linked. This repo cannot push to your remote without your credentials.

## 1. Apply database migrations

From the `akuko` directory (where `supabase/config.toml` lives):

```bash
cd akuko
supabase link --project-ref <your-project-ref>   # once per machine
supabase db push
```

Confirm migrations **0007_improvements.sql** and **0008_ecosystem.sql** are applied (Dashboard → Database → Migrations, or `supabase migration list`).

## 2. Promote an admin user

In Supabase SQL editor (service role):

```sql
update public.profiles
set is_admin = true, role = 'admin'
where id = '<auth-user-uuid>';
```

## 3. Configure and run the admin app

```bash
cd admin
cp .env.example .env.local
# Set VITE_SUPABASE_URL and VITE_SUPABASE_ANON_KEY
npm install
npm run dev
```

Sign in at <http://localhost:5173> with the promoted admin account.

## 4. Smoke checks

| Page | Expected |
|------|----------|
| **Settings** | Lists seeded `feature_flags`; toggling updates without full page reload |
| **Books** | Status badges; filter tabs; approve/reject on `pending_review` rows |
| **Books → Upload** | New row has `status = pending_review` unless fast-publish checked |
| **Authors** | Author list with book counts; pending section if any `reader` + `author_id` profiles |
| **Publishers** | Table loads (may be empty); approve/suspend updates `publishers.status` |
| **Payments** | `payment_transactions` table if webhooks have written rows |
| **Analytics** | Last 50 `analytics_events` or warning if 0008 not applied |

## 5. Production build (optional)

```bash
cd admin
npm run build
npm run preview
```

Host `dist/` on Vercel/Netlify with build-time `VITE_*` env vars set.
