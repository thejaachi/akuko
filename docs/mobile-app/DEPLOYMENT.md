# Akuko — Production Deployment Guide

Covers environment management, Supabase production hardening, mobile build &
signing, CI/CD, monitoring, and a go-live checklist.

> For the concise, copy-pasteable go-live checklist (full env-var tables,
> Paystack steps, and the flagged **deployment blockers**), see
> [`DEPLOYMENT_CHECKLIST.md`](./DEPLOYMENT_CHECKLIST.md).

---

## 1. Environments

Run **separate Supabase projects** per environment (`akuko-dev`, `akuko-staging`,
`akuko-prod`). Never share a database across environments.

| Concern | Client | Server / Edge |
|---------|--------|---------------|
| Supabase URL + anon key | `--dart-define` at build | auto-injected |
| Service role key | **never** | Edge function secret only |
| LLM/TTS keys | **never** | Edge function secret |

### Client config (`--dart-define`)

```bash
flutter run \
  --dart-define=AKUKO_SUPABASE_URL=https://<ref>.supabase.co \
  --dart-define=AKUKO_SUPABASE_ANON_KEY=<anon-key> \
  --dart-define=AKUKO_AUTH_REDIRECT=io.akuko.app://login-callback/
```

For repeatable builds, use a dart-define file:

```bash
flutter build apk --release --dart-define-from-file=env/prod.json
```

```json
// env/prod.json  (do NOT commit secrets; anon key is publishable but keep per-env)
{
  "AKUKO_SUPABASE_URL": "https://<ref>.supabase.co",
  "AKUKO_SUPABASE_ANON_KEY": "<anon>",
  "AKUKO_AUTH_REDIRECT": "io.akuko.app://login-callback/"
}
```

> The anon key is safe to ship (RLS protects data), but keep a distinct key per
> environment so you never point a prod build at dev data.

---

## 2. Supabase production hardening

- **RLS review:** confirm every table has RLS enabled and no overly-broad
  policy. Run a quick audit:

```sql
select relname, relrowsecurity
from pg_class
where relnamespace = 'public'::regnamespace and relkind = 'r'
order by relname;   -- relrowsecurity must be true for all
```

- **Service role** is used only inside Edge Functions/webhooks. Rotate keys if
  ever exposed (Dashboard → Settings → API → "Generate new").
- **Auth:** enable email confirmations; set strong password policy; restrict
  the redirect URL allow-list to real schemes/domains only.
- **Custom SMTP:** Dashboard → **Authentication → SMTP Settings**. Configure a
  provider (Resend/SendGrid/SES) so auth emails don't hit the shared sandbox
  limits. Set sender name/address and verify SPF/DKIM.
- **Backups:** enable **Point-in-Time Recovery** (Pro plan) or scheduled daily
  backups. Periodically test a restore into a scratch project.
- **Storage:** verify `book-files` is private; confirm signed-URL flow; set
  sensible bucket size/MIME limits (done in `0004_storage.sql`).
- **Rate limiting / abuse:** put quotas around AI/TTS functions (per-user
  counters) to cap provider spend.
- **Database:** add any missing indexes surfaced by `pg_stat_statements`; set up
  `Database → Reports` alerts.

---

## 3. Migrations in production

Migrations are the source of truth. Apply via CI (preferred) or manually:

```bash
supabase link --project-ref <prod-ref>
supabase db push          # applies pending migrations 0001 → 0007
```

Migration chain (forward-only): `0001_schema` → `0002_rls` →
`0003_functions_triggers` → `0004_storage` → `0005_seed` →
`0006_subscriptions` (canonical `subscriptions` + `is_premium()`) →
`0007_improvements` (`authors`, `downloads`, missing indexes/constraints,
`profiles`/`ai_summaries` RLS tightening, `subscriptions` Realtime).

Keep migrations forward-only and reviewed. **For production, keep `0005_seed.sql`
out of the prod chain** so sample books/plans don't ship to prod (move it into
`supabase/seed.sql`, which only runs on local `db reset`, or skip it in CI).

`0007` also adds `public.subscriptions` to the `supabase_realtime` publication
(guarded) so client entitlement state updates live after the webhook fires.

---

## 4. Android build & signing (Play Store)

> The `android/` project is owned by the Flutter worker; this is the release
> procedure they should follow.

1. Generate an upload keystore:

```bash
keytool -genkey -v -keystore upload-keystore.jks \
  -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

2. Configure `android/key.properties` (git-ignored) and reference it in
   `android/app/build.gradle` `signingConfigs`.
3. Build an app bundle:

```bash
flutter build appbundle --release --dart-define-from-file=env/prod.json
```

4. Upload `build/app/outputs/bundle/release/app-release.aab` to Play Console.
   Enroll in **Play App Signing**. Complete data-safety + content rating forms.
5. Ensure the Google OAuth Android client uses the **Play App Signing SHA-1**
   (not just the upload key) once enrolled.

---

## 5. iOS build & signing (App Store)

1. In Apple Developer, create the App ID (`io.akuko.app`), enable capabilities
   (Associated Domains if using universal links).
2. Create distribution certificate + App Store provisioning profile (or use
   automatic signing in Xcode).
3. Register the custom URL scheme `io.akuko.app` in `Info.plist`.
4. Build & archive:

```bash
flutter build ipa --release --dart-define-from-file=env/prod.json
```

5. Upload via Xcode Organizer or `xcrun altool`/Transporter to App Store
   Connect; submit for TestFlight then review.

---

## 6. CI/CD (GitHub Actions outline)

Two pipelines: **backend** (migrations + functions) and **app** (build/test).

```yaml
# .github/workflows/backend.yml
name: backend
on:
  push:
    branches: [main]
    paths: ["akuko/supabase/**"]
jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: supabase/setup-cli@v1
        with: { version: latest }
      - run: supabase link --project-ref ${{ secrets.SUPABASE_PROJECT_REF }}
        env: { SUPABASE_ACCESS_TOKEN: ${{ secrets.SUPABASE_ACCESS_TOKEN }} }
      - run: supabase db push
      - run: |
          supabase functions deploy signed-url
          supabase functions deploy ai-summary
          supabase functions deploy reading-assistant
          supabase functions deploy tts
          supabase functions deploy paystack-initialize
          supabase functions deploy paystack-verify
          supabase functions deploy paystack-cancel
          supabase functions deploy paystack-webhook --no-verify-jwt
```

> The Paystack **webhook** must be deployed with `--no-verify-jwt`: it is a
> server-to-server callback (no Supabase JWT) secured instead by HMAC-SHA512
> signature verification inside the function. After deploy, set the webhook URL
> `https://<ref>.supabase.co/functions/v1/paystack-webhook` in the Paystack
> dashboard and ensure `PAYSTACK_SECRET_KEY` matches the dashboard secret key.

```yaml
# .github/workflows/app.yml
name: app
on: { pull_request: {}, push: { branches: [main] } }
jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with: { flutter-version: "3.x", channel: stable }
      - run: flutter pub get
      - run: flutter analyze
      - run: flutter test
      - run: flutter build apk --release --dart-define-from-file=env/prod.json
```

**Secrets:** `SUPABASE_ACCESS_TOKEN`, `SUPABASE_PROJECT_REF`, plus signing
secrets (keystore base64, key passwords) for release builds. Function provider
keys are set once via `supabase secrets set`, not in CI.

---

## 7. Monitoring & observability

- **App:** Sentry (Flutter) for crashes + performance; Firebase Analytics or
  PostHog for product events.
- **Backend:** Supabase Dashboard logs (Postgres, Auth, Storage, Edge Functions);
  enable log drains to your provider if needed.
- **Edge functions:** structured logging + alert on `5xx` / provider failures;
  track AI/TTS spend per user.
- **DB health:** watch `pg_stat_statements`, connection counts, and slow queries;
  alert on error rate and CPU.

---

## 8. Go-live checklist

- [ ] Prod Supabase project created, region chosen, DB password stored in vault
- [ ] All migrations applied via `supabase db push` (no manual schema drift)
- [ ] RLS enabled on **every** table (audit query passes)
- [ ] Seed/sample data excluded from prod (or intentionally included)
- [ ] Auth: email confirmations on, custom SMTP verified, redirect allow-list locked down
- [ ] Google OAuth configured with prod SHA-1 / bundle id + web client id
- [ ] Storage buckets correct (`book-files` private); signed-url + premium gating tested
- [ ] Edge functions deployed (incl. 4 Paystack fns; webhook `--no-verify-jwt`); secrets set (`PAYSTACK_SECRET_KEY`, `LLM_API_KEY`, `LLM_MODEL`, `TTS_API_KEY`, `TTS_PROVIDER`, `CORS_ALLOW_ORIGIN`)
- [ ] Paystack dashboard webhook URL set; Realtime enabled on `public.subscriptions`
- [ ] Backups / PITR enabled and a restore tested
- [ ] Client built with prod `--dart-define`; service role key absent from app
- [ ] Android signed (Play App Signing) + iOS signed; store listings complete
- [ ] Monitoring/alerting live (Sentry + Supabase logs); AI/TTS spend caps in place
- [ ] Legal: privacy policy, terms, data-safety forms submitted
