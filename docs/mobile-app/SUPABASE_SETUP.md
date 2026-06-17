# Akuko — Supabase Setup Guide

Step-by-step provisioning for local dev and a hosted Supabase project. All paths
are relative to the repo root (`akuko/`).

---

## 0. Prerequisites

- **Supabase CLI** ≥ 1.200 — `npm i -g supabase` (or `brew install supabase/tap/supabase`)
- **Docker Desktop** (for `supabase start` local stack)
- A Supabase account + organization
- For Google sign-in: a Google Cloud project with OAuth consent screen

Verify:

```bash
supabase --version
docker --version
```

---

## 1. Create the hosted project

1. Go to <https://supabase.com/dashboard> → **New project**.
2. Name it `akuko`, choose a region close to your users, set a strong DB password.
3. Wait for provisioning, then open **Project Settings → API** and copy:
   - **Project URL** → `SUPABASE_URL`
   - **anon public** key → `SUPABASE_ANON_KEY`
   - **service_role** key → `SUPABASE_SERVICE_ROLE_KEY` (**server/Edge only — never ship to the client**)
4. From **Project Settings → General**, copy the **Reference ID** (`<project-ref>`).

---

## 2. Local development stack (optional but recommended)

```bash
cd akuko
supabase start          # boots Postgres, Auth, Storage, Studio in Docker
supabase status         # prints local URLs + anon/service keys
```

Local Studio is at <http://localhost:54323>. The config lives in
`supabase/config.toml`.

---

## 3. Run the migrations

The migrations live in `supabase/migrations/` and run in numeric order:

| File | Purpose |
|------|---------|
| `0001_schema.sql` | tables, constraints, indexes, extensions |
| `0002_rls.sql` | RLS enable + policies + `is_admin()` |
| `0003_functions_triggers.sql` | triggers & helper functions |
| `0004_storage.sql` | buckets + storage policies |
| `0005_seed.sql` | categories, sample books, plans |

### Local

```bash
supabase db reset       # drops, recreates, runs all migrations + seed
```

### Hosted

```bash
# Link the repo to your hosted project (one-time)
supabase link --project-ref <project-ref>

# Push migrations to the hosted database
supabase db push
```

> `0005_seed.sql` is a normal migration here, so it also runs on `db push`.
> If you prefer seed data NOT to ship to production, move its contents into
> `supabase/seed.sql` (which only runs on local `db reset`) instead.

---

## 4. Auth providers

### 4.1 Email / password

Dashboard → **Authentication → Providers → Email**: enable. Enable
**Confirm email** for production. Customize templates under
**Authentication → Email Templates** (see custom SMTP in `DEPLOYMENT.md`).

### 4.2 Google OAuth

1. **Google Cloud Console → APIs & Services → Credentials → Create OAuth client ID**.
   - For the **web** portion of the flow Supabase uses, create a **Web application** client.
   - Authorized redirect URI:
     `https://<project-ref>.supabase.co/auth/v1/callback`
2. For native Flutter sign-in you typically also create **Android** and **iOS**
   OAuth client IDs (using your app's package name / bundle id and SHA-1 for
   Android). Note the **Web client ID** — it is the `serverClientId` passed to
   `google_sign_in` on the client.
3. Supabase Dashboard → **Authentication → Providers → Google**: enable, paste
   the **Web client ID** and **client secret**.
4. Dashboard → **Authentication → URL Configuration**:
   - **Site URL**: `io.akuko.app://login-callback/`
   - **Redirect URLs** (allow-list), add:
     - `io.akuko.app://login-callback/`  (mobile deep link — note trailing slash)
     - `http://localhost:3000`           (web dev, if applicable)

> The client resolves this value from the `AKUKO_AUTH_REDIRECT` env var
> (default `io.akuko.app://login-callback/`). The allow-list entry must match
> **exactly**, including the trailing slash.

### 4.3 Flutter deep link / redirect

The client signs in with:

```dart
await supabase.auth.signInWithOAuth(
  OAuthProvider.google,
  redirectTo: 'io.akuko.app://login-callback/',
);
```

Register the custom scheme so the OS routes the callback back to the app:

- **Android** (`android/app/src/main/AndroidManifest.xml`): add an
  `<intent-filter>` with `<data android:scheme="io.akuko.app" android:host="login-callback"/>`.
- **iOS** (`ios/Runner/Info.plist`): add `CFBundleURLTypes` with URL scheme
  `io.akuko.app`.

> These client files are owned by the Flutter worker — this section documents
> the exact scheme/host the backend redirect URLs expect.

---

## 5. Storage buckets

`0004_storage.sql` creates the buckets and policies automatically:

- `book-files` — private (signed-URL access only)
- `book-covers` — public read, admin write
- `avatars` — public read, owner write (objects under `avatars/<uid>/…`)

Verify in Dashboard → **Storage**. To upload catalog assets as an admin, either
use Studio or the CLI/SDK with the service role.

---

## 6. Deploy Edge Functions

```bash
# Deploy all functions
supabase functions deploy signed-url
supabase functions deploy ai-summary
supabase functions deploy reading-assistant
supabase functions deploy tts
```

Functions are invoked from the client via the SDK:

```dart
final res = await supabase.functions.invoke('signed-url',
    body: {'bookId': bookId});
```

---

## 7. Set secrets

`SUPABASE_URL`, `SUPABASE_ANON_KEY`, and `SUPABASE_SERVICE_ROLE_KEY` are injected
into functions automatically. Set the external provider keys + CORS origin:

```bash
supabase secrets set \
  LLM_API_KEY=sk-...            \
  LLM_MODEL=gpt-4o-mini         \
  TTS_API_KEY=...               \
  TTS_PROVIDER=elevenlabs       \
  CORS_ALLOW_ORIGIN=https://app.akuko.io

# List configured secrets
supabase secrets list
```

For Google OAuth via CLI-managed config, also export locally:

```bash
export GOOGLE_OAUTH_CLIENT_ID=...
export GOOGLE_OAUTH_SECRET=...
```

---

## 8. Promote an admin

Catalog writes require `profiles.is_admin = true`. After a user signs up, set it
once via Studio SQL editor (service role):

```sql
update public.profiles set is_admin = true where id = '<auth-user-uuid>';
```

---

## 9. Client configuration

The Flutter app initializes Supabase with the **anon** key only, reading these
client env vars (resolved from `--dart-define` first, then `.env`):

| Client var | Meaning |
|------------|---------|
| `AKUKO_SUPABASE_URL` | Project URL |
| `AKUKO_SUPABASE_ANON_KEY` | anon/public key |
| `AKUKO_AUTH_REDIRECT` | OAuth deep link (default `io.akuko.app://login-callback/`) |

```dart
await Supabase.initialize(
  url: Env.supabaseUrl,        // AKUKO_SUPABASE_URL
  anonKey: Env.supabaseAnonKey, // AKUKO_SUPABASE_ANON_KEY
);
```

Pass values at build time with `--dart-define` (see `DEPLOYMENT.md`). **Never**
embed the service-role key in the client.

---

## 10. Quick verification checklist

- [ ] `supabase db push` succeeds with no errors
- [ ] `select * from public.categories;` returns 8 rows
- [ ] `select count(*) from public.books;` returns 12
- [ ] New signup auto-creates a `profiles` row (and `reading_streaks`)
- [ ] Anonymous client can read `books`/`categories` but not `reading_progress`
- [ ] `functions.invoke('signed-url', ...)` returns a URL for a free book
- [ ] Premium book returns `402` without an active subscription
