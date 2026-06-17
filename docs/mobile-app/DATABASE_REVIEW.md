# Akuko — Database Review (Migrations 0001–0006)

> Evidence-based review of every migration in `supabase/migrations/`
> (`0001_schema.sql`, `0002_rls.sql`, `0003_functions_triggers.sql`,
> `0004_storage.sql`, `0005_seed.sql`, `0006_subscriptions.sql`). Findings that
> were safe to apply additively are implemented in **`0007_improvements.sql`**;
> the rest are documented here as recommendations. No prior migration was edited.

---

## 1. Scope & method

Each migration was read in full. Tables, primary/foreign keys, unique
constraints, CHECK constraints, indexes, RLS policies, functions and triggers
were catalogued, then checked against the canonical spec and the actual query
patterns in the Flutter datasources and edge functions. Severities:

- **High** — security exposure or correctness risk.
- **Medium** — performance or integrity gap likely to bite at scale.
- **Low** — cleanliness / future-proofing.

---

## 2. Findings

| # | Issue | Severity | Fix | Where | Status |
|---|-------|----------|-----|-------|--------|
| F1 | `profiles_select_all USING (true)` exposes **every** profile row — including `is_admin` and `bio` — to any authenticated user. | **High** | Drop the read-all policy; add owner/admin-only select; expose only public columns via a `public_profiles` view. | `0002_rls.sql` §profiles | **Fixed in 0007** (§5a) |
| F2 | `ai_summaries_select_all` lets any authenticated user read cached AI output, which is a premium feature. | **High** | Restrict select to `is_premium(auth.uid())` or admin; keep writes service-role-only. | `0002_rls.sql` §ai_summaries | **Fixed in 0007** (§5b) |
| F3 | **No `authors` table** — `books.author` is free text, so no author entity, bio, photo, or dedupe; misspellings fragment the catalog. | Medium | Add normalized `authors` + nullable `books.author_id` FK (keep `author` text); backfill + index. | `0001_schema.sql` §books | **Fixed in 0007** (§1) |
| F4 | **No `downloads` table** — only `books.download_count`, so the free-tier download cap (`Entitlements.maxFreeDownloads = 3`) cannot be enforced or audited per user. | Medium | Add `downloads (user_id, book_id, file_type, downloaded_at)` with owner-only RLS + indexes. | `0001_schema.sql` / `signed-url` TODO | **Fixed in 0007** (§2) |
| F5 | `reading_list_items.book_id` FK has **no index** (only `list_id` is indexed). Slows "which lists contain book X" and `books` delete cascades. | Medium | `create index idx_reading_list_items_book on reading_list_items(book_id)`. | `0001_schema.sql` | **Fixed in 0007** (§3) |
| F6 | `user_subscriptions.plan_id` FK (`on delete restrict`) has **no index** → seq scan on every plan mutation and on plan→subscription joins. | Medium | `create index idx_user_subscriptions_plan on user_subscriptions(plan_id)`. | `0001_schema.sql` | **Fixed in 0007** (§3) |
| F7 | Missing **value constraints**: `books.price`, `rating_count`, `download_count`, `file_size_bytes` could go negative; `rating_avg` unbounded; `reading_progress.progress_percent` not bounded to 0–100; `reading_goals.target` could be ≤0; `subscription_plans.price` unbounded. | Medium | Add non-negative / range CHECKs (guarded, idempotent). | `0001_schema.sql` | **Fixed in 0007** (§4) |
| F8 | **Overlap:** the new canonical `subscriptions` table (0006) overlaps the legacy `subscription_plans` + `user_subscriptions` (0001). Two sources of truth for entitlement invite drift. | Medium | Adopt `subscriptions` + `is_premium()` as the single source of truth (already done in `signed-url`/`tts`/client guard). Treat `subscription_plans` as a **price catalog only** and deprecate `user_subscriptions`. See §3. | `0001` vs `0006` | Documented (no destructive change) |
| F9 | `subscriptions` billing window has no ordering check (`current_period_end` could precede `current_period_start`). | Low | Add `check (period_end >= period_start)` when both present. | `0006_subscriptions.sql` | **Fixed in 0007** (§4) |
| F10 | `0005_seed.sql` lives in the numbered migration chain, so `supabase db push` seeds demo categories/books/plans into **production**. | Medium | Move seed content to `supabase/seed.sql` (runs only on local `db reset`) or gate behind an env flag. | `0005_seed.sql` | Documented (deployment) — see `DEPLOYMENT.md` / `DEPLOYMENT_CHECKLIST.md` |
| F11 | CORS defaults to `*` in `_shared/cors.ts` (`CORS_ALLOW_ORIGIN ?? "*"`). | Low/Medium | Set `CORS_ALLOW_ORIGIN` to the real web origin in production. | `supabase/functions/_shared/cors.ts` | Documented (deployment) |
| F12 | No realtime publication entry for `public.subscriptions`, yet the client wants live entitlement updates after the webhook flips a row. | Low | Add `subscriptions` to `supabase_realtime` (guarded). | `0006_subscriptions.sql` | **Fixed in 0007** (§6) |

### Verified-OK (no change needed)

- **RLS coverage** — RLS is enabled on all 16 base tables (0002) and on
  `subscriptions` (0006). `downloads`/`authors` get RLS in 0007.
- **Owner-write protection** on `user_subscriptions` and `subscriptions` (no
  client insert/update policy → service-role only). Users cannot self-grant
  premium. Correct and intentional.
- **`is_admin()` / `is_premium()`** are `security definer` with a fixed
  `search_path = public`, so policy use does not recurse and is injection-safe.
- **Existing indexes** on `books` (category, partial flag indexes, `created_at`,
  GIN trigram on title/author), `reading_progress(user_id,last_read_at)`,
  `notifications(user_id,is_read,created_at)`, `reviews(book_id)` are appropriate.
- **`ai_summaries.book_id`** lookups are already served by the leading column of
  the `uq_ai_summaries_lookup(book_id, summary_type, chapter_ref)` unique index —
  no extra index added.
- **`uq_ai_summaries_lookup` `nulls not distinct`** correctly guarantees a single
  whole-book summary row and enables `ON CONFLICT` inference in the edge function.

---

## 3. Canonical subscription path (resolving F8)

Three subscription-related tables now exist. To avoid divergence, the canonical
model going forward is:

| Table | Role | Written by |
|-------|------|-----------|
| `subscriptions` (0006) | **Source of truth** for entitlement (one row per user, `plan` free/premium, Paystack codes, period window). `is_premium(uid)` reads only this table. | Paystack edge functions (service role) |
| `subscription_plans` (0001) | **Price catalog** for display (name, price, interval, features JSON). Maps to Paystack plan codes via `PAYSTACK_PLAN_MONTHLY/YEARLY` env. | Admin |
| `user_subscriptions` (0001) | **Deprecated** for entitlement. Kept for backwards compatibility; not read by `signed-url`/`tts`/client guard anymore. | (legacy / service role) |

`0007` does **not** drop `user_subscriptions` (forward-only, non-destructive). A
future migration may drop it once confirmed unused; the recommendation is
recorded here rather than executed.

---

## 4. What `0007_improvements.sql` actually does

1. **`authors`** table (`id, name unique, bio, photo_url, created_at`) + GIN
   trigram index on `name`; `books.author_id uuid → authors(id) on delete set
   null` + index; idempotent backfill from distinct `books.author`; public-read /
   admin-write RLS.
2. **`downloads`** table (`id, user_id → profiles, book_id → books, file_type,
   downloaded_at`) + indexes `(user_id, downloaded_at)`, `(book_id)`,
   `(user_id, book_id)`; owner-only select/insert/delete RLS.
3. **Indexes**: `idx_reading_list_items_book`, `idx_user_subscriptions_plan`.
4. **Constraints** (guarded, idempotent): non-negative `books` price/counters/
   size, `rating_avg` in [0,5], `page_count > 0`, `reading_progress.progress_percent`
   in [0,100], `reading_goals.target > 0`, `subscription_plans.price >= 0`,
   `subscriptions` period ordering.
5. **Security**: drop `profiles_select_all`; add `profiles_select_own` (owner or
   admin); add `public_profiles` view (id, full_name, avatar_url, bio — no
   `is_admin`); replace `ai_summaries_select_all` with premium/admin-only read.
6. **Realtime**: add `public.subscriptions` to `supabase_realtime` (guarded).

All statements are `if not exists` / `create or replace` / `drop policy if
exists` + `create` / DO-block guarded, so the migration is safe to re-apply.

### Client compatibility note

Dropping `profiles_select_all` means selecting **other** users' rows directly
from `profiles` now returns nothing for non-admins. The current client only
reads the signed-in user's own profile, so this is safe today; any future
feature that shows other users (review authors, public list owners) should read
the `public_profiles` view instead of the base table.
