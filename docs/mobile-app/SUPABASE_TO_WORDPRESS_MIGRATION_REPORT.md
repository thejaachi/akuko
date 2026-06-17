# Supabase → WordPress Akuko Mobile API Migration Report

**Flutter project:** `akuko/`  
**Target base URL:** `https://books.ikikearts.com/wp-json/akuko/v1/`  
**Audit date:** 2026-06-17  
**Status:** Migration complete (Phase 1 audit + Phase 2 implementation)

---

## 1. Supabase Dependencies (pubspec.yaml)

| Package | Version | Purpose |
|---------|---------|---------|
| `supabase_flutter` | ^2.5.6 | Postgrest, GoTrue auth, Storage, Edge Functions, Realtime |
| `google_sign_in` | ^6.2.1 | Google OAuth token exchange via Supabase GoTrue |

**Related (non-Supabase but coupled):**
- `http` ^1.2.2 — will become primary HTTP client
- `shared_preferences` ^2.2.3 — session bits + local fallbacks
- `flutter_dotenv` ^5.1.0 — env loading (`AKUKO_SUPABASE_*`)

**Env keys (`.env.example`):**
- `AKUKO_SUPABASE_URL`
- `AKUKO_SUPABASE_ANON_KEY`
- `AKUKO_AUTH_REDIRECT` (OAuth redirect for Supabase)

---

## 2. Supabase Services / Datasources / Repositories

### Core network & config
| File | Role |
|------|------|
| `lib/core/network/supabase_client_provider.dart` | Riverpod: `SupabaseClient`, `GoTrueClient`, `authStateChangesProvider` |
| `lib/core/config/supabase_config.dart` | URL, anon key, auth redirect |
| `lib/core/config/env.dart` | `AKUKO_SUPABASE_*` resolution, `isConfigured` gate |
| `lib/core/constants/app_constants.dart` | `SupabaseTables` table name constants |
| `lib/main.dart` | `Supabase.initialize()` bootstrap |

### Auth
| File | Role |
|------|------|
| `lib/features/auth/data/datasources/auth_remote_datasource.dart` | GoTrue: email/password, Google ID token, password reset |
| `lib/features/auth/data/repositories/supabase_auth_repository.dart` | Maps `User` → `AuthUser` |
| `lib/features/auth/presentation/controllers/auth_controller.dart` | Wires `supabaseClientProvider` |

### Books & authors
| File | Role |
|------|------|
| `lib/features/books/data/datasources/book_remote_datasource.dart` | Postgrest: books, categories, search |
| `lib/features/books/data/repositories/supabase_book_repository.dart` | Book catalogue repository |
| `lib/features/authors/data/datasources/author_remote_datasource.dart` | Postgrest: authors table |

### Reading & downloads
| File | Role |
|------|------|
| `lib/features/reader/data/datasources/reading_remote_datasource.dart` | Postgrest: progress, bookmarks |
| `lib/features/reader/data/repositories/supabase_reading_repository.dart` | Reading sync repository |
| `lib/features/reader/data/datasources/book_file_remote_datasource.dart` | Edge function `signed-url` |

### Library
| File | Role |
|------|------|
| `lib/features/library/data/datasources/library_remote_datasource.dart` | Postgrest: continue-reading join |
| `lib/features/library/data/repositories/supabase_library_repository.dart` | Library repository |
| `lib/features/library/data/repositories/book_request_repository.dart` | Postgrest: book_requests |

### Subscriptions & payments
| File | Role |
|------|------|
| `lib/features/subscriptions/data/datasources/subscription_remote_datasource.dart` | Postgrest + Realtime: subscriptions |
| `lib/features/subscriptions/data/repositories/supabase_subscription_repository.dart` | Subscription + Paystack orchestration |
| `lib/features/subscriptions/data/services/paystack_service.dart` | Edge functions: paystack-initialize/verify/cancel |

### Profile, wallet, streaks, notifications
| File | Role |
|------|------|
| `lib/features/profile/data/datasources/profile_remote_datasource.dart` | Postgrest: profiles |
| `lib/features/profile/data/repositories/supabase_profile_repository.dart` | Profile repository |
| `lib/features/profile/presentation/controllers/transaction_providers.dart` | Direct Postgrest: payment_transactions, subscriptions |
| `lib/features/profile/presentation/pages/security_privacy_page.dart` | Direct `Supabase.instance.client.auth.updateUser` |
| `lib/features/wallet/data/repositories/supabase_wallet_repository.dart` | Postgrest: wallets, wallet_transactions + Paystack |
| `lib/features/streaks/data/datasources/streak_remote_datasource.dart` | Postgrest: reading_streaks |
| `lib/features/streaks/data/repositories/supabase_streak_repository.dart` | Streak repository |
| `lib/features/notifications/data/datasources/notification_remote_datasource.dart` | Postgrest: notifications |

### Feature flags & analytics
| File | Role |
|------|------|
| `lib/core/feature_flags/supabase_feature_flag_repository.dart` | Postgrest: feature_flags |
| `lib/core/analytics/supabase_analytics_service.dart` | Postgrest: analytics_events |

### Reading circles & dictionary
| File | Role |
|------|------|
| `lib/features/reading_circles/data/repositories/circle_social_repository.dart` | Postgrest: circle_posts, likes, comments, follows |
| `lib/features/reader/data/dictionary_usage_repository.dart` | Postgrest: dictionary_lookups + local prefs |

---

## 3. All API Calls (Supabase)

### Postgrest tables
| Table | Operations | Used by |
|-------|------------|---------|
| `books` | select, filter, search | BookRemoteDataSource |
| `categories` | select | BookRemoteDataSource |
| `authors` | select | AuthorRemoteDataSource |
| `profiles` | select, update | ProfileRemoteDataSource, CircleSocialRepository |
| `reading_progress` | upsert, select | ReadingRemoteDataSource, LibraryRemoteDataSource |
| `bookmarks` | insert, select, delete | ReadingRemoteDataSource |
| `subscriptions` | select, stream | SubscriptionRemoteDataSource, transaction_providers |
| `wallets` | select, upsert | SupabaseWalletRepository |
| `wallet_transactions` | select, insert | SupabaseWalletRepository |
| `payment_transactions` | select | transaction_providers |
| `notifications` | select, insert, update | NotificationRemoteDataSource |
| `reading_streaks` | select | StreakRemoteDataSource |
| `feature_flags` | select | SupabaseFeatureFlagRepository |
| `analytics_events` | insert | SupabaseAnalyticsService |
| `book_requests` | insert, select | BookRequestRepository |
| `dictionary_lookups` | select, insert | DictionaryUsageRepository |
| `circle_posts` | CRUD | CircleSocialRepository |
| `circle_post_likes` | select, insert, delete | CircleSocialRepository |
| `circle_post_comments` | select, insert | CircleSocialRepository |
| `user_follows` | select, insert, delete | CircleSocialRepository |

### Edge functions
| Function | Body | Used by |
|----------|------|---------|
| `signed-url` | `{ bookId, expiresIn }` | BookFileRemoteDataSource |
| `paystack-initialize` | planCode/amount/currency/metadata | PaystackService |
| `paystack-verify` | `{ reference }` | PaystackService |
| `paystack-cancel` | `{}` | PaystackService |

### GoTrue (Auth SDK)
| Operation | Used by |
|-----------|---------|
| `signInWithPassword` | AuthRemoteDataSource |
| `signUp` | AuthRemoteDataSource |
| `signInWithIdToken` (Google) | AuthRemoteDataSource |
| `resetPasswordForEmail` | AuthRemoteDataSource |
| `signOut` | AuthRemoteDataSource |
| `onAuthStateChange` | authStateChangesProvider |
| `updateUser` (password) | SecurityPrivacyPage |

### Storage
No direct Supabase Storage calls in `lib/` (covers/files served via signed URLs through edge function).

### Realtime
| Channel | Used by |
|---------|---------|
| `subscriptions` stream | SubscriptionRemoteDataSource.watchMySubscription |

---

## 4. Auth Usage

- **Bootstrap:** `main.dart` calls `Supabase.initialize(url, anonKey)`; aborts with `_ConfigErrorApp` if env missing.
- **Session:** JWT managed by Supabase SDK; `supabaseClientProvider` exposes singleton client.
- **Auth state:** `authStateChangesProvider` streams GoTrue `AuthState`; `currentUserProvider` drives GoRouter redirects.
- **Protected calls:** Datasources read `_client.auth.currentUser?.id` for RLS-scoped rows.
- **Google OAuth:** `google_sign_in` → `signInWithIdToken(provider: google)` — must be replaced/stubbed.
- **Password change:** `SecurityPrivacyPage` calls `Supabase.instance.client.auth.updateUser` directly.

---

## 5. Data Models Tied to Supabase

Models map snake_case Postgrest JSON; no Supabase types in domain layer:

| Model | Entity | Supabase table |
|-------|--------|----------------|
| `BookModel` | `Book` | `books` (+ embedded `categories`) |
| `ReadingProgressModel` | `ReadingProgress` | `reading_progress` |
| `BookmarkModel` | `Bookmark` | `bookmarks` |
| `ProfileModel` | `Profile` | `profiles` |
| `SubscriptionModel` | `Subscription` | `subscriptions` |
| `AppNotificationModel` | `AppNotification` | `notifications` |
| `LibraryEntry` builders | `LibraryEntry` | `reading_progress` + `books` join |

`AuthUser` is domain-only (mapped from Supabase `User` in repository).

Field mapping notes for WP API:
- Reading: `location` ↔ `position`, `progress_percent` ↔ `percentage`
- Bookmarks: `location` ↔ `cfi`

---

## 6. Storage Usage

- **No Supabase Storage SDK usage** in Flutter `lib/`.
- Book files accessed via **`signed-url` edge function** returning temporary URL.
- Cover images use public `cover_url` on book rows (`cached_network_image`).

**Migration:** `POST /downloads/{book_id}/request` with `format` (epub|pdf|audio).

---

## 7. Files to Modify vs Delete

### Delete / gut
| File | Action |
|------|--------|
| `lib/core/network/supabase_client_provider.dart` | **Delete** → `api_client_provider.dart` |
| `lib/core/config/supabase_config.dart` | **Delete** → `api_config.dart` |
| `lib/core/feature_flags/supabase_feature_flag_repository.dart` | **Replace** with API-backed repo |
| `lib/core/analytics/supabase_analytics_service.dart` | **Replace** with API-backed service |

### Modify (replace Supabase with API)
All files listed in §2 datasources/repositories/providers, plus:
- `lib/main.dart`
- `lib/core/config/env.dart`
- `.env.example`
- `pubspec.yaml`
- `test/widget_test.dart`
- `lib/features/profile/presentation/pages/security_privacy_page.dart`

### Stub (no WP endpoint yet)
| Feature | Notes |
|---------|-------|
| Wallet (cowries) | Local prefs fallback; no `/wallet` in API.md |
| Reading streaks | No endpoint; keep local/mock |
| Reading circles social | No endpoint; mock/TODO |
| Book requests | No endpoint; local queue/TODO |
| Paystack initialize | No `/payments/initialize`; verify via `/payments/verify` |
| Paystack cancel subscription | No cancel endpoint |
| Google sign-in | Stub TODO until WP OAuth |
| Dictionary lookups server sync | Local prefs only |
| Password change (in-app) | TODO: `/auth/reset-password` flow |

---

## 8. Endpoint Mapping Table

| Old Supabase call | New WordPress API endpoint | Notes |
|-------------------|---------------------------|-------|
| `auth.signInWithPassword` | `POST /auth/login` | Returns `access_token`, `refresh_token`, `user` |
| `auth.signUp` | `POST /auth/register` | `first_name`/`last_name` split from `fullName` |
| `auth.signOut` | `POST /auth/logout` | Optional `refresh_token` body |
| `auth.resetPasswordForEmail` | `POST /auth/forgot-password` | |
| Token refresh (SDK auto) | `POST /auth/refresh` | Body: `refresh_token` |
| `auth.currentUser` / session | `GET /auth/me` | Profile + device sessions |
| `auth.signInWithIdToken(google)` | **No endpoint** | Stub TODO |
| `auth.updateUser(password)` | `POST /auth/reset-password` | Requires email token flow |
| `from('books').select()` | `GET /books` | `page`, `per_page`, `category` |
| `from('books').eq('id')` | `GET /books/{id}` | |
| `is_featured` filter | `GET /books/featured` | `limit` query |
| `is_trending` filter | `GET /books/trending` | |
| `is_new_release` filter | `GET /books/new-releases` | |
| Category by slug | `GET /categories` + `GET /books?category=` | |
| `or(title.ilike...)` search | `GET /search?q=` | min 2 chars |
| Related books | `GET /books/{id}/related` | |
| `from('authors')` | `GET /authors`, `GET /authors/{id}` | |
| `from('reading_progress')` get | `GET /reading/progress/{book_id}` | Field remap |
| `reading_progress` upsert | `PUT /reading/progress/{book_id}` | `position`, `percentage`, `chapter` |
| `from('bookmarks')` | `GET/POST/DELETE /bookmarks` | POST: `book_id`, `cfi`, `label` |
| `from('highlights')` | `GET/POST/DELETE /highlights` | Not yet wired in Flutter |
| `from('notes')` | `GET/POST/DELETE /notes` | Not yet wired in Flutter |
| Library / continue reading | `GET /library`, `GET /library/continue-reading` | Auth required |
| Edge `signed-url` | `POST /downloads/{book_id}/request` | Body: `format` |
| `from('subscriptions')` | `GET /premium/status` | Poll replaces Realtime |
| Edge `paystack-verify` | `POST /payments/verify` | Body: `reference` |
| Premium activation | `POST /premium/subscribe` | Body: `reference` |
| Payment history | `GET /payments/history` | |
| Edge `paystack-initialize` | **No endpoint** | Gap — checkout init broken until WP adds route |
| Edge `paystack-cancel` | **No endpoint** | Gap |
| `from('profiles')` | `GET /auth/me` + profile update via UserApi | |
| `from('notifications')` | `GET /notifications` | |
| Push token | `POST /notifications/device-token` | `token`, `platform` |
| `from('feature_flags')` | `GET /feature-flags` | |
| `from('analytics_events').insert` | `POST /analytics/event` | `event`, `payload` |
| `from('wallets')` | **No endpoint** | Local stub |
| `from('reading_streaks')` | **No endpoint** | Local stub |
| `from('book_requests')` | **No endpoint** | Local stub |
| Reading circles tables | **No endpoint** | Mock/stub |
| `from('dictionary_lookups')` | **No endpoint** | Local prefs only |
| Home recommendations | `GET /recommendations/home` | Optional enhancement |
| App settings | `GET /settings` | Optional |
| Reviews | `GET/POST /books/{id}/reviews` | Feature module exists, not Supabase-wired |
| Wishlist | `GET/POST/DELETE /wishlist` | Not Supabase-wired today |

### Endpoint mismatches vs common user spec
| User spec (generic) | Actual API.md path |
|----------------------|-------------------|
| `/login` | `/auth/login` |
| `/register` | `/auth/register` |
| `/me` | `/auth/me` |
| `/refresh` | `/auth/refresh` |

---

## Section 2 — Post-Implementation Summary

*(Updated after Phase 2 implementation)*

### Dependencies removed
- `supabase_flutter` removed from `pubspec.yaml`
- `google_sign_in` retained but Google login stubbed (TODO: WP OAuth)

### Files created
- `lib/core/config/api_config.dart`
- `lib/core/api/token_storage.dart`
- `lib/core/api/api_client.dart`
- `lib/core/api/auth_api.dart`
- `lib/core/api/books_api.dart`
- `lib/core/api/reading_api.dart`
- `lib/core/api/premium_api.dart`
- `lib/core/api/payments_api.dart`
- `lib/core/api/downloads_api.dart`
- `lib/core/api/user_api.dart`
- `lib/core/api/notifications_api.dart`
- `lib/core/api/analytics_api.dart`
- `lib/core/api/feature_flags_api.dart`
- `lib/core/network/api_client_provider.dart`
- `lib/core/auth/auth_session_manager.dart`
- `lib/core/feature_flags/api_feature_flag_repository.dart`
- `lib/core/analytics/api_analytics_service.dart`
- `lib/features/auth/data/repositories/api_auth_repository.dart`

### Files modified
- All Supabase datasources rewritten to use `AkukoApiClient`
- All `*providers.dart` wired to `apiClientProvider`
- `main.dart`, `env.dart`, `.env.example`, `pubspec.yaml`, `failures.dart`, `exceptions.dart`
- `security_privacy_page.dart`, `transaction_providers.dart`, `dictionary_usage_repository.dart`
- `circle_social_repository.dart` stubbed
- `test/widget_test.dart`

### Files deleted
- `lib/core/network/supabase_client_provider.dart`
- `lib/core/config/supabase_config.dart`
- `lib/core/feature_flags/supabase_feature_flag_repository.dart`
- `lib/core/analytics/supabase_analytics_service.dart`
- `lib/features/auth/data/repositories/supabase_auth_repository.dart`

### Auth / books / reading migration summary
- **Auth:** JWT stored in `shared_preferences`; login/register/refresh/logout/me via `/auth/*`; auth state via `AuthSessionManager` stream.
- **Books:** Catalogue, search, categories, authors via REST; curated home content kept as offline fallback.
- **Reading:** Progress, bookmarks via `/reading/*` and `/bookmarks`; field mapping applied.
- **Downloads:** Signed URLs via `POST /downloads/{id}/request`.
- **Premium:** Status via `GET /premium/status`; verify via `POST /payments/verify`; subscribe via `POST /premium/subscribe`.

### Remaining risks
| Risk | Severity |
|------|----------|
| No Paystack initialize endpoint — card checkout may not work | High |
| No subscription cancel endpoint | Medium |
| Google sign-in stubbed | Medium |
| Wallet/cowries server sync unavailable | Medium |
| Reading circles, streaks, book requests stubbed | Low |
| Realtime subscription updates replaced with polling | Low |
| In-app password change not wired | Low |

### App readiness score
**72 / 100** — Core auth, catalogue, reading sync, downloads, and premium status migrate cleanly. Payment checkout init, wallet server sync, and social features need backend endpoints or follow-up work.
