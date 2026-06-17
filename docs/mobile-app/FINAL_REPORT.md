# Akuko — Final Engineering Report

> Consolidated report for the Akuko (Flutter + Supabase ebook reader)
> engagement, Tasks 1–9. File inventories are derived by inspecting the repo at
> `c:\Users\HP\Documents\New project 2\akuko` (no git history was available in
> this environment, so "modified" vs "new" is attributed from project context +
> file inspection, not from a diff). Cross-references: [`AUDIT.md`](./AUDIT.md),
> [`DATABASE_REVIEW.md`](./DATABASE_REVIEW.md), [`ERD.md`](./ERD.md),
> [`DATABASE_SCHEMA.md`](./DATABASE_SCHEMA.md), [`DEPLOYMENT.md`](./DEPLOYMENT.md),
> [`DEPLOYMENT_CHECKLIST.md`](./DEPLOYMENT_CHECKLIST.md).

---

## 1. Engagement at a glance

Akuko is a Clean-Architecture Flutter app (Riverpod + GoRouter + Material 3) on
a Supabase backend (Postgres + RLS, Auth, Storage, Edge Functions). The
engagement audited the existing codebase, made the reader functional, added a
Paystack-backed premium subscription system end-to-end, then reviewed and
hardened the database and prepared for deployment.

> **Build verification caveat:** the Flutter/Dart SDK is **not installed** in
> this environment. `flutter pub get` / `analyze` / `test` and on-device reader
> rendering are **unverified** and remain deployment blockers (see §7).

---

## 2. Completed tasks

| Task | Title | Status | Primary artifacts |
|------|-------|--------|-------------------|
| 1 | Codebase audit | Complete | `docs/AUDIT.md` |
| 2 | Reader implementation (EPUB + PDF) | Complete (code); on-device render unverified 🚩 | `lib/features/reader/**` (`epub_view` + `pdfx`), signed-URL loading + 402 handling |
| 3 | Signed-URL client wiring | Complete | `book_file_remote_datasource.dart`, `book_file_providers.dart` → `signed-url` fn |
| 4 | Canonical subscription schema | Complete | `supabase/migrations/0006_subscriptions.sql` (`subscriptions`, `is_premium()`) |
| 5 | Paystack backend (init/verify/webhook/cancel) | Complete | `supabase/functions/paystack-*`, `_shared/paystack.ts` |
| 6 | Subscriptions feature + premium gating (client) | Complete | `lib/features/subscriptions/**`, `lib/core/guards/subscription_guard.dart`, gated Read button, `/subscription` route |
| 7 | Database review → improved migration | **Complete (this session)** | `supabase/migrations/0007_improvements.sql`, `docs/DATABASE_REVIEW.md` |
| 8 | ERD (Mermaid) | **Complete (this session)** | `docs/ERD.md`, refreshed `docs/DATABASE_SCHEMA.md` |
| 9 | Deployment preparation | **Complete (this session)** | `docs/DEPLOYMENT_CHECKLIST.md`, extended `docs/DEPLOYMENT.md` |

### Task 7 — top DB-review fixes applied in `0007_improvements.sql`
1. **`profiles` over-exposure fixed** — dropped `profiles_select_all USING(true)`
   (leaked `is_admin`/`bio` to all auth users); added owner/admin-only select +
   a column-safe `public_profiles` view.
2. **`ai_summaries` reads gated** — replaced read-all with premium-or-admin only.
3. **`authors` table** added (normalized) + `books.author_id` nullable FK +
   trigram index + idempotent backfill from `books.author`.
4. **`downloads` table** added with owner-only RLS + indexes (backs the free vs
   unlimited download quota).
5. **Missing indexes** — `reading_list_items(book_id)`,
   `user_subscriptions(plan_id)`.
6. **Data constraints** — non-negative/range CHECKs on `books` price/counters/
   rating/size, `reading_progress.progress_percent` 0–100, `reading_goals.target
   > 0`, `subscription_plans.price >= 0`, `subscriptions` period ordering.
7. **Realtime** — `public.subscriptions` added to `supabase_realtime` (guarded).
8. **Documented (not destructive):** canonical subscription path —
   `subscriptions` is the source of truth; `subscription_plans` = price catalog;
   `user_subscriptions` deprecated.

---

## 3. Remaining tasks / known gaps

- 🚩 **Install Flutter SDK & verify the build** — `pub get`, `analyze`, `test`,
  and EPUB/PDF on-device rendering are unverified (Tasks 2/6 code only).
- 🚩 **Reader package-API confirmation** — verify `epub_view`/`pdfx` widget APIs
  and the `location` (CFI / page-index) contract on device.
- **AI features are server-stubbed** — `ai-summary` / `reading-assistant` return
  placeholder text until `LLM_API_KEY`/`LLM_MODEL` are set and the provider call
  is implemented; no AI client UI yet (gate with `SubscriptionGuard.canUseAI()`).
- **TTS/audiobooks server-stubbed** — `tts` returns `501`/`202` until
  `TTS_API_KEY`/`TTS_PROVIDER` set and synthesis/upload implemented; no client UI.
- **Download quota not yet wired to `downloads`** — table + guard exist; the
  client/`signed-url` should record rows and enforce `maxFreeDownloads`.
- **Phase-2 client stubs** still single-file: `reviews`, `reading_lists`,
  `goals`, `ai`, `tts`, `notifications`, `admin`.
- **Optional future migration** — drop deprecated `user_subscriptions` once
  confirmed unused; backfill richer `authors` metadata (bio/photo).

---

## 4. Files modified (during the engagement)

> Attributed from project context + inspection (no git diff available).

**This session (Tasks 7–9):**
- `docs/DATABASE_SCHEMA.md` — refreshed ERD + per-table refs + RLS table for
  `subscriptions`/`authors`/`downloads` and the `0007` policy tightening.
- `docs/DEPLOYMENT.md` — Paystack functions in deploy/CI, webhook
  `--no-verify-jwt`, `0006`/`0007` in the migration chain, checklist additions,
  pointer to `DEPLOYMENT_CHECKLIST.md`.

**Earlier tasks (per project context):**
- `lib/features/reader/presentation/widgets/epub_reader_view.dart`,
  `pdf_reader_view.dart` — real renderers (replaced stubs).
- `lib/features/reader/presentation/pages/reader_page.dart` — signed-URL load +
  402 premium handling.
- `lib/features/books/presentation/pages/book_detail_page.dart` — gated Read
  button.
- `lib/core/router/app_router.dart`, `lib/core/router/routes.dart` —
  `/subscription` route.
- `pubspec.yaml` — `epub_view`, `pdfx`, `webview_flutter`, `url_launcher`,
  `http` (removed `flutter_epub_viewer`/Syncfusion).
- `supabase/config.toml` — registered the 4 Paystack functions (webhook
  `verify_jwt=false`).
- `supabase/functions/signed-url/index.ts`, `tts/index.ts` — premium gating via
  `subscriptions` / `is_premium()`.
- `.env.example` — Paystack public/plan/currency keys + secret-handling notes.

---

## 5. New files created

**Docs (this session):**
- `docs/DATABASE_REVIEW.md`
- `docs/ERD.md`
- `docs/DEPLOYMENT_CHECKLIST.md`
- `docs/FINAL_REPORT.md`

**Docs (earlier):** `docs/AUDIT.md`

**Flutter — subscriptions feature (`lib/features/subscriptions/**`):**
- `domain/entities/subscription.dart`, `entitlements.dart`, `paystack_transaction.dart`
- `domain/repositories/subscription_repository.dart`
- `data/models/subscription_model.dart`
- `data/datasources/subscription_remote_datasource.dart`
- `data/services/paystack_service.dart`
- `data/repositories/supabase_subscription_repository.dart`
- `presentation/controllers/subscription_controller.dart`, `subscription_providers.dart`
- `presentation/pages/subscription_page.dart`, `paystack_checkout_page.dart`

**Flutter — core / reader plumbing:**
- `lib/core/guards/subscription_guard.dart`
- `lib/features/reader/data/datasources/book_file_remote_datasource.dart`
- `lib/features/reader/presentation/controllers/book_file_providers.dart`

**Supabase functions — shared:**
- `supabase/functions/_shared/paystack.ts`
- `supabase/functions/_shared/cors.ts`

---

## 6. Migration & edge-function inventory

**Migration files (`supabase/migrations/`):**

| File | Purpose | Origin |
|------|---------|--------|
| `0001_schema.sql` | 16 core tables + indexes/constraints | pre-existing |
| `0002_rls.sql` | RLS enable + policies | pre-existing |
| `0003_functions_triggers.sql` | `is_admin`, `handle_new_user`, triggers | pre-existing |
| `0004_storage.sql` | buckets + storage RLS | pre-existing |
| `0005_seed.sql` | demo data (keep out of prod 🚩) | pre-existing |
| `0006_subscriptions.sql` | canonical `subscriptions` + `is_premium()` | engagement |
| **`0007_improvements.sql`** | authors, downloads, indexes, constraints, RLS tightening, realtime | **this session** |

**Edge functions (`supabase/functions/`):**

| Function | Purpose | `verify_jwt` |
|----------|---------|--------------|
| `signed-url` | premium-gated short-lived book-file URL | true |
| `ai-summary` | cached AI summaries (provider STUB) | true |
| `reading-assistant` | book Q&A (provider STUB) | true |
| `tts` | premium-gated TTS (provider STUB) | true |
| `paystack-initialize` | start checkout / subscription | true |
| `paystack-verify` | verify a transaction post-checkout | true |
| `paystack-cancel` | cancel auto-renew | true |
| `paystack-webhook` | HMAC-verified event sink → writes `subscriptions` | **false** |

Paystack webhook handles: `charge.success`, `subscription.create`,
`subscription.disable`, `invoice.create`, `invoice.payment_failed`.

---

## 7. Manual actions required (before go-live)

> Full detail + copy-paste commands in
> [`DEPLOYMENT_CHECKLIST.md`](./DEPLOYMENT_CHECKLIST.md). Most critical
> deployment blockers, in priority order:

1. 🚩 **Install Flutter SDK; run `flutter pub get` / `analyze` / `test`** and
   smoke-test EPUB + PDF rendering on a real device — currently unverified.
2. 🚩 **Provide all config** — client `--dart-define`s (`AKUKO_SUPABASE_URL`,
   `AKUKO_SUPABASE_ANON_KEY`, `AKUKO_AUTH_REDIRECT`, `PAYSTACK_PUBLIC_KEY`,
   `PAYSTACK_CURRENCY`, `PAYSTACK_PLAN_MONTHLY/YEARLY`) and edge secrets
   (`PAYSTACK_SECRET_KEY`, `LLM_API_KEY`, `LLM_MODEL`, `TTS_API_KEY`,
   `TTS_PROVIDER`, `CORS_ALLOW_ORIGIN`). Blank `.env` → app boots into the config
   error screen.
3. 🚩 **Keep `0005_seed.sql` out of the prod migration chain** (move to
   `supabase/seed.sql` or skip in CI) so demo data doesn't ship to production.
4. 🚩 **Apply migrations `0001`→`0007`** (`supabase db push`) and verify the
   `0007` security tightening (profiles owner/admin-only, `public_profiles` view,
   `ai_summaries` premium-only).
5. 🚩 **Deploy all edge functions**, with the webhook as
   `supabase functions deploy paystack-webhook --no-verify-jwt`.
6. 🚩 **Configure the Paystack dashboard webhook** to
   `https://<ref>.supabase.co/functions/v1/paystack-webhook` and ensure
   `PAYSTACK_SECRET_KEY` matches the dashboard secret (HMAC verification).
7. 🚩 **Enable Realtime on `public.subscriptions`** (auto via `0007`; verify in
   Dashboard → Replication).
8. 🚩 **Lock CORS** — set `CORS_ALLOW_ORIGIN` to the real web origin (defaults `*`).
9. 🚩 **Google OAuth** — configure Android/iOS/web client IDs + Play App Signing
   SHA-1; set `GOOGLE_OAUTH_CLIENT_ID/SECRET`.
10. 🚩 **Flutter web only:** run `dart run pdfx:install_web` for PDF rendering.
11. Configure AI/TTS providers (keys above) to replace the STUB responses.
12. Android/iOS release signing + store listings (see `DEPLOYMENT_CHECKLIST.md`
    §6–§7).
