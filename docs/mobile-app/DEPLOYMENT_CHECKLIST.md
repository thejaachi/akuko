# Akuko — Deployment Checklist

> Focused, actionable go-live checklist covering the full stack (Supabase +
> Paystack + Flutter/Android/iOS). Complements the narrative guide in
> [`DEPLOYMENT.md`](./DEPLOYMENT.md). **Deployment blockers are flagged with
> 🚩** — every 🚩 must be resolved (or consciously accepted) before production.

---

## 0. Deployment blockers (resolve first) 🚩

| # | Blocker | Why it blocks | Resolution |
|---|---------|---------------|-----------|
| B1 | **Flutter SDK not installed / `pub get` unverified** in this environment | Cannot compile, resolve deps, `analyze`, `test`, or build any artifact | Install Flutter ≥ 3.22, run `flutter pub get`, `flutter analyze`, `flutter test` on a real machine/CI |
| B2 | **Reader package-API TODOs** | `epub_view` / `pdfx` wiring in the reader views must be confirmed against the resolved package APIs (versions never resolved here) | Build & smoke-test EPUB + PDF rendering on device after `pub get` |
| B3 | **Missing keys / blank `.env`** | App boots into `_ConfigErrorApp`; Paystack/LLM/TTS features are inert | Provide all client `--dart-define`s and set all edge secrets (§2, §3) |
| B4 | **`0005_seed.sql` in the prod migration chain** | `supabase db push` seeds demo categories/books/plans into production | Move seed to `supabase/seed.sql` (local-only) or skip it in the prod pipeline |
| B5 | **CORS defaults to `*`** (`_shared/cors.ts`) | Any origin may call the edge functions from a browser | Set `CORS_ALLOW_ORIGIN` to the real web origin secret |
| B6 | **`profiles` over-exposure** | Pre-`0007`, all profiles (incl. `is_admin`) were world-readable | Apply `0007` (tightens policy + adds `public_profiles` view) and verify |
| B7 | **Google OAuth client IDs not in repo** | Native Google sign-in fails without platform client IDs | Configure Android/iOS/web OAuth client IDs + SHA-1; set `GOOGLE_OAUTH_CLIENT_ID/SECRET` |
| B8 | **Web target needs `pdfx` web assets** | PDF rendering on Flutter web requires the pdfium web worker | Run `dart run pdfx:install_web` (or vendor the assets) if shipping web |
| B9 | **Paystack dashboard webhook not configured** | Subscriptions never activate (webhook is the only writer of `subscriptions`) | Set webhook URL + verify HMAC secret = `PAYSTACK_SECRET_KEY` (§4) |

---

## 1. Production checklist

- [ ] Prod Supabase project created; region chosen; DB password in a vault
- [ ] All migrations `0001`→`0007` applied via `supabase db push` (no manual drift)
- [ ] `0005_seed.sql` excluded from prod (B4) — or demo data intentionally accepted
- [ ] RLS enabled on **every** table incl. `subscriptions`, `authors`, `downloads`
- [ ] `0007` security tightening verified: `profiles` owner/admin-only,
      `public_profiles` view present, `ai_summaries` premium/admin-only
- [ ] All edge functions deployed (incl. 4 Paystack functions); webhook with `--no-verify-jwt`
- [ ] All edge secrets set (`supabase secrets list` shows them) (§3)
- [ ] Realtime enabled on `public.subscriptions` (auto via `0007`; verify in Dashboard)
- [ ] Paystack dashboard webhook URL configured + signature secret matches (§4)
- [ ] Auth: email confirmations on, custom SMTP verified, redirect allow-list locked
- [ ] Google OAuth: prod client IDs + SHA-1 / bundle id + web client id (B7)
- [ ] Storage: `book-files` private; signed-url + premium gating tested end-to-end
- [ ] Backups / PITR enabled; a restore tested into a scratch project
- [ ] Client built with prod `--dart-define`; **service role key absent from app**
- [ ] CORS locked to the web origin (B5)
- [ ] Android signed (Play App Signing) + iOS signed; store listings complete
- [ ] Monitoring/alerting live (Sentry + Supabase logs); AI/TTS spend caps in place
- [ ] Legal: privacy policy, terms, data-safety/App Privacy forms submitted

---

## 2. Environment variables — client (build-time)

Pass via `--dart-define` / `--dart-define-from-file`. The anon key is
publishable (RLS protects data) but keep a distinct key per environment.
**Never** put the service role or any secret key in the client.

| Variable | Example | Notes |
|----------|---------|-------|
| `AKUKO_SUPABASE_URL` | `https://<ref>.supabase.co` | Project Settings → API → Project URL |
| `AKUKO_SUPABASE_ANON_KEY` | `eyJhbGciOi...` | anon/public key (per env) |
| `AKUKO_AUTH_REDIRECT` | `io.akuko.app://login-callback/` | Must match `config.toml` + platform URL scheme |
| `PAYSTACK_PUBLIC_KEY` | `pk_live_...` | **Public** key only — safe to ship |
| `PAYSTACK_CURRENCY` | `NGN` | Currency for amount-based charges |
| `PAYSTACK_PLAN_MONTHLY` | `PLN_xxx` | Paystack monthly plan code (optional → falls back to one-off charge) |
| `PAYSTACK_PLAN_YEARLY` | `PLN_yyy` | Paystack yearly plan code (optional) |

```json
// env/prod.json  (do NOT commit; anon/public keys are per-env)
{
  "AKUKO_SUPABASE_URL": "https://<ref>.supabase.co",
  "AKUKO_SUPABASE_ANON_KEY": "<anon>",
  "AKUKO_AUTH_REDIRECT": "io.akuko.app://login-callback/",
  "PAYSTACK_PUBLIC_KEY": "pk_live_xxx",
  "PAYSTACK_CURRENCY": "NGN",
  "PAYSTACK_PLAN_MONTHLY": "PLN_xxx",
  "PAYSTACK_PLAN_YEARLY": "PLN_yyy"
}
```

## 3. Environment variables — edge function secrets (server-side)

Set with `supabase secrets set KEY=value`. **Never** ship these in the client.

| Secret | Used by | Notes |
|--------|---------|-------|
| `PAYSTACK_SECRET_KEY` | `paystack-*` | `sk_live_...`. Also the HMAC key the webhook verifies signatures with |
| `LLM_API_KEY` | `ai-summary`, `reading-assistant` | Provider API key (functions return STUB output without it) |
| `LLM_MODEL` | `ai-summary`, `reading-assistant` | e.g. `gpt-4o-mini` |
| `TTS_API_KEY` | `tts` | Without it `tts` returns `501 not_configured` |
| `TTS_PROVIDER` | `tts` | e.g. `elevenlabs` |
| `CORS_ALLOW_ORIGIN` | `_shared/cors.ts` (all functions) | Set to the real web origin; defaults to `*` 🚩 |
| `SUPABASE_SERVICE_ROLE_KEY` | all functions | **Auto-injected** by Supabase — do not set manually |
| `SUPABASE_URL` | all functions | Auto-injected |

```bash
supabase secrets set \
  PAYSTACK_SECRET_KEY=sk_live_xxx \
  LLM_API_KEY=xxx LLM_MODEL=gpt-4o-mini \
  TTS_API_KEY=xxx TTS_PROVIDER=elevenlabs \
  CORS_ALLOW_ORIGIN=https://app.akuko.example
supabase secrets list
```

---

## 4. Supabase deployment steps

```bash
# 1. Link to the prod project
supabase link --project-ref <prod-ref>

# 2. Apply migrations 0001→0007 (forward-only)
#    🚩 B4: ensure 0005_seed.sql is NOT in the prod chain (move to supabase/seed.sql).
supabase db push

# 3. Deploy ALL edge functions. The webhook MUST skip JWT verification
#    (it is a Paystack server-to-server callback secured by HMAC-SHA512).
supabase functions deploy signed-url
supabase functions deploy ai-summary
supabase functions deploy reading-assistant
supabase functions deploy tts
supabase functions deploy paystack-initialize
supabase functions deploy paystack-verify
supabase functions deploy paystack-cancel
supabase functions deploy paystack-webhook --no-verify-jwt

# 4. Set secrets (see §3)
supabase secrets set PAYSTACK_SECRET_KEY=sk_live_xxx CORS_ALLOW_ORIGIN=https://app.akuko.example ...

# 5. Enable Realtime on the canonical subscriptions table.
#    0007 adds it to the supabase_realtime publication automatically; verify in
#    Dashboard → Database → Replication, or run:
#      alter publication supabase_realtime add table public.subscriptions;
```

**Paystack dashboard (🚩 B9):**
- Dashboard → Settings → API Keys & Webhooks → **Webhook URL**:
  `https://<ref>.supabase.co/functions/v1/paystack-webhook`
- The webhook function verifies `x-paystack-signature` (HMAC-SHA512) using
  `PAYSTACK_SECRET_KEY` — the dashboard secret key and the edge secret **must
  match**.
- Create the recurring **Plans** (monthly/yearly), copy their plan codes into
  `PAYSTACK_PLAN_MONTHLY` / `PAYSTACK_PLAN_YEARLY` (client build).
- Confirm handled events arrive: `charge.success`, `subscription.create`,
  `subscription.disable`, `invoice.create`, `invoice.payment_failed`.

---

## 5. Flutter deployment steps

🚩 **B1/B2:** Flutter is **not installed** in the authoring environment, so
`pub get`, `analyze`, `test`, and reader rendering are **unverified**. Run on a
real machine/CI:

```bash
flutter --version            # ensure >= 3.22 (sdk >=3.4.0 <4.0.0)
flutter pub get              # resolve epub_view, pdfx, webview_flutter, url_launcher, http
flutter analyze              # must pass
flutter test                 # must pass

# Web only (🚩 B8): install pdfx web assets before building web
dart run pdfx:install_web

# Run / build with prod config
flutter run --dart-define-from-file=env/prod.json
```

---

## 6. Android release steps (Play Store)

```bash
# 1. Generate an upload keystore (once; store outside the repo)
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

- [ ] Copy `android/key.properties.example` → `android/key.properties`
      (git-ignored) and fill in passwords, alias, and `storeFile` path
- [ ] Confirm `android/app/build.gradle.kts` picks up `signingConfigs.release`
      when `key.properties` exists (falls back to debug signing otherwise)
- [ ] Build the signed app bundle:

```bash
flutter build appbundle --release --dart-define-from-file=env/prod.json
```

- [ ] Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console;
      enroll in **Play App Signing**
- [ ] Set the Google OAuth Android client to the **Play App Signing SHA-1** (B7)
- [ ] Complete data-safety + content-rating forms; create the store listing

---

## 7. iOS release steps (App Store)

- [ ] Apple Developer: create App ID `io.akuko.app`; enable capabilities
- [ ] Distribution certificate + App Store provisioning profile (or Xcode
      automatic signing)
- [ ] Register the custom URL scheme `io.akuko.app` in `Info.plist`
- [ ] Build & archive:

```bash
flutter build ipa --release --dart-define-from-file=env/prod.json
```

- [ ] Upload via Xcode Organizer / Transporter to App Store Connect
- [ ] TestFlight → submit for review; complete App Privacy questionnaire

---

## 8. Post-deploy smoke test

- [ ] Sign up → `profiles` + `reading_streaks` + free `subscriptions` row created
- [ ] Open a free book → signed URL issued → reader renders (EPUB + PDF)
- [ ] Open a premium book as free user → `402 premium required` → paywall shown
- [ ] Subscribe via Paystack checkout → webhook flips `subscriptions.plan=premium`
      → entitlements update live (Realtime) → premium book opens
- [ ] Cancel → `paystack-cancel` → access retained until period end (`non-renewing`)
- [ ] Confirm a non-admin user cannot read other users' `profiles` rows directly
