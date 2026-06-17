# Akuko Ecosystem Audit

> Generated during the mandatory pre-refactor checkpoint (Phase 0 + Phase 1).
> Inspection only — no changes to `lib/`, Supabase migrations, or edge functions
> beyond adding this document.

---

## 1. Git checkpoint result

| Field | Value |
|-------|--------|
| Workspace root | `c:\Users\HP\Documents\New project 2` |
| Repository | **Initialized** (`git init`) — was not a Git repo before this run |
| Branch | `akuko-refactor-architecture` (created from baseline commit) |
| Commit | `dc26253e933848c4bf69a2352a6dc2c899afafaa` |
| Commit message | `baseline: pre-akuko-architecture-refactor` |
| Files in commit | **288** files (entire workspace monorepo: `akuko/`, `book-publishing-calculator/`, `dist/`, plugins, etc.) |
| Notes | Git was not on PATH; Git 2.54.0 was installed via winget. Local-only `user.name` / `user.email` set for this repo to allow the commit. Root `.gitignore` created. |

---

## 2. Current architecture summary

**Client (`akuko/lib/`, 98 Dart files under `lib/`):**

- **Pattern:** Clean Architecture per feature — `data/` (datasources, models, Supabase repos), `domain/` (entities, repository interfaces), `presentation/` (Riverpod + pages/widgets).
- **Core:** `lib/core/config/` (`env.dart`, `supabase_config.dart`), `lib/core/router/app_router.dart` (GoRouter + auth redirect + bottom shell), `lib/core/guards/subscription_guard.dart`, theme/widgets/utils/errors.
- **Implemented features (full layers):** `auth`, `books`, `reader`, `library`, `profile`, **`subscriptions`** (12 files — Paystack checkout, entitlements, subscription page).
- **Stub features (single `*_feature.dart`, `library;` only):** `admin`, `ai`, `reviews`, `goals`, `notifications`, `reading_lists`, `tts` — see `lib/features/<name>/<name>_feature.dart`.
- **Bootstrap:** `lib/main.dart` → `Env.isConfigured` → `Supabase.initialize` → `lib/app.dart` (`MaterialApp.router`).

**Backend (`akuko/supabase/`):**

- **Migrations:** `0001_schema.sql` … `0007_improvements.sql` (7 files).
- **Edge functions:** `signed-url`, `ai-summary`, `reading-assistant`, `tts`, `paystack-initialize`, `paystack-verify`, `paystack-webhook`, `paystack-cancel`, `_shared/cors.ts`, `_shared/paystack.ts`.
- **Storage (from docs/migrations):** buckets `book-files` (private), `book-covers`, `avatars`; book content path on `books.file_url`, not a separate `book_files` table.

**Docs:** Rich set under `akuko/docs/` including `AUDIT.md`, `FINAL_REPORT.md`, `CANONICAL_SPEC.md`, `DATABASE_REVIEW.md`, `ERD.md`, `ROADMAP.md`.

**Vision alignment (Kindle + Wattpad + Medium + Substack + Selar + Audible):** Today the repo is primarily **Kindle-like reader + storefront + Paystack premium**. Wattpad/Medium-style social writing, Substack newsletters, Selar creator commerce, and publisher royalty ops are **not** modeled in schema or UI yet.

---

## 3. Gap analysis — PHASED LAUNCH

### Phase 1 launch list (`docs/CANONICAL_SPEC.md` — MVP)

| Capability | Spec (Phase 1) | Codebase status |
|------------|----------------|-----------------|
| Email auth + forgot password | Required | **Implemented** — `lib/features/auth/` |
| Google OAuth | Required | **Dependency present** (`google_sign_in` in `pubspec.yaml`); wiring in auth datasource — **not build-verified** |
| Profile | Required | **Implemented** — `lib/features/profile/` |
| Browse / search / categories / home sections | Required | **Implemented** — `lib/features/books/` |
| Book detail | Required | **Implemented** |
| EPUB + PDF reader + settings | Required | **Implemented** — `lib/features/reader/` (`epub_view`, `pdfx`) |
| Reading progress + bookmarks | Required | **Implemented** — reader + `reading_remote_datasource` |
| Signed URL for files | Required | **Implemented** — `book_file_remote_datasource.dart` + `supabase/functions/signed-url` |

**Ahead of spec (built but CANONICAL_SPEC labels Phase 2+):**

| Capability | Spec phase | Codebase status |
|------------|------------|-----------------|
| Subscriptions / Paystack | Phase 2+ in spec | **Implemented** — `0006_subscriptions.sql`, paystack edge functions, `lib/features/subscriptions/**` |
| Premium gating | Phase 2+ | **Partial** — `subscription_guard.dart`, signed-url/tts server checks; AI edge **not** premium-gated server-side per guard comments |

### Hidden / later phases (Phase 2–4 in product sense)

| Area | DB tables exist? | Flutter UI? |
|------|------------------|---------------|
| Highlights, notes | Yes (`0001`) | **No** — reader widgets only bookmarks |
| Reviews | Yes | **Stub** — `reviews_feature.dart` |
| Reading lists | Yes | **Stub** |
| Goals / streaks | Yes | **Stub** |
| Notifications | Yes | **Stub** |
| AI summaries / assistant | `ai_summaries` + edge fns | **Stub** client; **edge functions present** |
| TTS / Audible-like | Edge `tts` | **Stub** client |
| Admin / moderation | `profiles.is_admin` only | **Stub**; **no separate admin app** in workspace |
| Publisher / author payouts | Partial (`authors` in 0007) | **No** publisher portal, royalties, withdrawals |
| Feature flags | **Missing** | **None** |
| Analytics pipeline | **Missing** | **None** |

---

## 4. Database — exists vs required ecosystem tables

**Present in migrations (public schema):**

`profiles`, `categories`, `books`, `reading_progress`, `bookmarks`, `highlights`, `notes`, `reviews`, `reading_lists`, `reading_list_items`, `reading_goals`, `reading_streaks`, `subscription_plans`, `user_subscriptions`, `ai_summaries`, `notifications`, `subscriptions` (0006), `authors`, `downloads` (0007).

**Auth:** `auth.users` (Supabase) — 1:1 with `profiles`.

**Not present (typical full ecosystem list):**

| Table | Status |
|-------|--------|
| `publishers` | **Missing** — only `books.publisher` text column |
| `publisher_members` | **Missing** |
| `book_files` (normalized file metadata) | **Missing** — `books.file_url` + Storage bucket `book-files` |
| `royalties` | **Missing** |
| `withdrawals` | **Missing** |
| `feature_flags` | **Missing** |
| `payment_transactions` | **Missing** — Paystack state on `subscriptions` + edge functions only |
| `analytics_events` | **Missing** |
| `admin_logs` | **Missing** |

**0007 improvements (not applied until deployed):** `authors`, `downloads`, RLS tightening on `profiles` and `ai_summaries`, indexes/CHECKs, `public_profiles` view, realtime on `subscriptions`. See `docs/DATABASE_REVIEW.md` and `supabase/migrations/0007_improvements.sql`.

---

## 5. Reader / AI / Subscription / Paystack status

| Component | Implemented | Stub / gap |
|-----------|-------------|------------|
| **Reader (EPUB/PDF)** | `reader_page.dart`, `epub_reader_view.dart`, `pdf_reader_view.dart`, progress/bookmarks datasources | On-device render **unverified** (no Flutter SDK in audit environment per `docs/AUDIT.md`) |
| **Signed URL load** | Client datasource + `signed-url` function with premium checks | Free-tier download **quota** table added in 0007 but client guard TODOs for quota UI |
| **Subscriptions** | Full Flutter feature + `subscriptions` table + `is_premium()` | Overlap with legacy `user_subscriptions` / `subscription_plans` (documented F8 in DATABASE_REVIEW) |
| **Paystack** | `paystack-initialize`, `verify`, `webhook`, `cancel`, `_shared/paystack.ts`, `paystack_checkout_page.dart` | Requires secrets + plan codes in `.env` / Supabase secrets |
| **AI** | Edge `ai-summary`, `reading-assistant` | **No** `lib/features/ai` UI; LLM keys required; **RLS fix for ai_summaries in 0007** |
| **TTS** | Edge `tts` (premium-gated in function) | **No** player UI; provider keys required |

---

## 6. Admin dashboard

- **Flutter:** `lib/features/admin/admin_feature.dart` — placeholder only (`TODO(phase2)`).
- **Router:** No admin routes in `lib/core/router/app_router.dart`.
- **Workspace:** No separate Next.js/React admin app under `akuko/` or repo root.
- **Conclusion:** **Admin dashboard is missing.** Operations rely on Supabase Dashboard + SQL until built.

---

## 7. Security issues (RLS, exposure) — reference 0007 fixes

Documented in `docs/DATABASE_REVIEW.md` and addressed in **`0007_improvements.sql`** (must be applied to remote DB):

1. **F1 — `profiles_select_all USING (true)`** exposed all profiles (including `is_admin`, `bio`) to any authenticated user → fixed by dropping policy + owner/admin select + `public_profiles` view.
2. **F2 — `ai_summaries` read-all** exposed premium AI cache to all authenticated users → premium/admin-only select.
3. **F11 — CORS `*`** in `supabase/functions/_shared/cors.ts` — deployment config risk.
4. **F10 — `0005_seed.sql` in migration chain** — demo data may land in production on `db push`.
5. **Client-only AI gating** — `subscription_guard.dart` notes AI edge functions are not premium-gated server-side yet.

Service-role-only writes on `subscriptions` (correct). `is_premium()` / `is_admin()` security definer functions in 0006/0003.

---

## 8. Placeholder / TODO inventory

| Location | Summary |
|----------|---------|
| `lib/features/admin/admin_feature.dart` | Phase 2 admin tooling |
| `lib/features/ai/ai_feature.dart` | Phase 2 AI UI |
| `lib/features/reviews/reviews_feature.dart` | Phase 2 reviews |
| `lib/features/goals/goals_feature.dart` | Phase 2 goals/streaks |
| `lib/features/notifications/notifications_feature.dart` | Phase 2 notifications |
| `lib/features/reading_lists/reading_lists_feature.dart` | Phase 2 lists |
| `lib/features/tts/tts_feature.dart` | Phase 2 TTS UI |
| `lib/core/guards/subscription_guard.dart` | TODO: gate AI UI, download quota UI, audiobook UI |
| `docs/AUDIT.md` | Lists subscriptions as stub — **stale** vs current `subscriptions` feature |
| `docs/CANONICAL_SPEC.md` | Subscriptions listed as Phase 2+ — **stale** vs implementation |

No `feature_flags` table or client flag reads found.

---

## 9. Recommended implementation order (ecosystem refactor)

1. **Deploy & verify baseline:** Apply `0007` to Supabase; run `flutter pub get`, analyze, test on device; configure `.env` / Paystack secrets / CORS.
2. **Align spec with reality:** Update `CANONICAL_SPEC.md` / `AUDIT.md` for subscriptions-in-MVP vs phased doc.
3. **Phase 1 hardening:** Google OAuth E2E; enforce download quota (wire `downloads` + guard); confirm signed-url 402 UX.
4. **Migration 0008 (ecosystem):** `feature_flags`, `publishers`, `publisher_members`, `payment_transactions`, `royalties`, `withdrawals`, `analytics_events`, `admin_logs`; optional `book_files` if multi-format per book.
5. **Feature flags service:** Read flags in Flutter router/guards; admin-toggle via dashboard.
6. **Admin dashboard (web):** Separate app or Supabase-backed internal UI — catalogue, users, flags, payouts, moderation.
7. **Phase 2 Flutter features:** reviews → reading_lists → highlights/notes in reader → goals/notifications.
8. **AI/TTS productization:** Client `ai` + `tts` features; server-side premium gate on `ai-summary` / `reading-assistant`.
9. **Creator/publisher economics:** Royalties engine, withdrawal workflow (Selar/Substack-like).
10. **Social/writing (Wattpad/Medium):** Out of current schema — new tables and feeds later phase.

---

## 10. Launch readiness score

**Score: 58 / 100** (Phase 1 reader MVP + payments code present; ecosystem and ops gaps large)

| Blocker | Severity |
|---------|----------|
| Flutter SDK / CI build & reader smoke test not verified | High |
| Remote Supabase may not have `0007` (security fixes) applied | High |
| No admin dashboard or `feature_flags` for safe rollout | High |
| Publisher/royalty/withdrawal schema absent for creator economy | Medium (Phase 2–4) |
| Community/AI/TTS UIs stubbed; AI server gating incomplete | Medium |
| Production seed migration (`0005`) risk | Medium |
| Docs drift (AUDIT vs subscriptions implementation) | Low |

---

## Appendix — Key paths

- App entry: `akuko/lib/main.dart`, `akuko/lib/app.dart`
- Router: `akuko/lib/core/router/app_router.dart`
- Migrations: `akuko/supabase/migrations/0001_schema.sql` … `0007_improvements.sql`
- Paystack: `akuko/supabase/functions/paystack-webhook/index.ts`, `akuko/lib/features/subscriptions/`
- Env template: `akuko/.env.example`
