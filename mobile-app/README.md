# Akuko

A modern **ebook reader + bookstore** for EPUB & PDF, built with Flutter and
Supabase. Akuko lets readers browse and search a catalogue, read with
customisable typography (font size, line spacing, Light/Dark/Sepia themes),
and sync reading progress and bookmarks across devices.

> The canonical data model is defined in [`docs/CANONICAL_SPEC.md`](docs/CANONICAL_SPEC.md)
> and is the single source of truth for both this client and the Supabase
> backend. Dart entities mirror those tables (DB `snake_case` → Dart `camelCase`).

---

## Tech stack

| Concern        | Choice                                                        |
| -------------- | ------------------------------------------------------------- |
| UI             | Flutter 3.x, Material 3                                       |
| State          | Riverpod (`flutter_riverpod`, hand-written providers)         |
| Navigation     | GoRouter (typed route layer + auth-aware redirects)           |
| Backend        | Supabase (`supabase_flutter`) — Auth, Postgres, Storage       |
| Auth           | Email/password, Google (`google_sign_in` + ID-token exchange) |
| EPUB rendering | `flutter_epub_viewer` *(see caveat below)*                    |
| PDF rendering  | `syncfusion_flutter_pdfviewer` *(see caveat below)*           |
| Images         | `cached_network_image`                                        |
| Local prefs    | `shared_preferences`                                          |
| Config         | `flutter_dotenv` + `--dart-define`                            |
| Fonts / i18n   | `google_fonts`, `intl`                                        |
| Error handling | Custom sealed `Result<T>` + `Failure` (no `dartz` dependency) |

### Package caveats

- **Reader rendering is stubbed.** `EpubReaderView` and `PdfReaderView` apply
  the live theme/typography settings and emit progress callbacks, but the
  actual page rendering is left as a clearly marked `TODO`. Swap in
  `flutter_epub_viewer`'s `EpubViewer` and `SfPdfViewer.network` to render real
  content. Everything around them (settings, progress sync, bookmarks) is fully
  wired.
- **Syncfusion** is free under a community license for qualifying teams but
  requires registering a license key for production. If that is undesirable,
  replace it with `pdfx` (the `PdfReaderView` seam makes this a one-file swap).
- Version constraints in `pubspec.yaml` are recent and plausible but were
  authored offline; run `flutter pub get` / `flutter pub upgrade` to resolve
  against the live pub.dev and adjust if needed.

---

## Architecture

Clean Architecture with **feature-first** folders. Each feature is split into
three layers:

- **domain/** — entities, abstract repository interfaces, (use cases). Pure
  Dart, no Flutter/Supabase imports.
- **data/** — datasources (Supabase), models (JSON ↔ entity mappers), and the
  concrete repository implementation.
- **presentation/** — pages, widgets, and Riverpod controllers/providers.

The dependency rule points inward: `presentation → domain ← data`. The
**Repository Pattern** keeps Supabase behind an interface; data sources throw
typed `AppException`s which repositories translate into `Failure`s and return
inside a `Result<T>`. Providers unwrap `Result` via `getOrThrow()` so domain
failures surface as `AsyncError` and render through the shared `ErrorView`.

```
Widget → Provider/Controller → Repository (domain interface)
                                   │
                          Supabase*Repository (data)
                                   │
                            RemoteDataSource → Supabase
```

---

## Folder structure

```
lib/
  main.dart                  # bootstrap: env, Supabase.init, SharedPreferences, runApp
  app.dart                   # MaterialApp.router + themes + ProviderScope consumer
  core/
    config/                  # env.dart, supabase_config.dart, shared_preferences_provider.dart
    constants/               # app_constants.dart (+ Supabase table names)
    theme/                   # app_theme.dart, app_colors.dart, reader_theme.dart, theme_controller.dart
    router/                  # app_router.dart, routes.dart, main_shell.dart
    error/                   # failures.dart (sealed), exceptions.dart
    utils/                   # result.dart, validators.dart, responsive.dart, extensions.dart
    network/                 # supabase_client_provider.dart
    widgets/                 # app_button, app_text_field, loading/error/empty views
  features/
    auth/                    # email/Google sign-in, register, forgot password
    books/                   # home sections, search, category, book detail
    reader/                  # epub/pdf reader, settings sheet, progress + bookmarks
    profile/                 # profile + reading preferences
    library/                 # continue-reading list (light MVP)
    reviews/ reading_lists/ goals/ subscriptions/
    ai/ tts/ notifications/ admin/    # Phase 2 placeholders (structure only)
  shared/
    domain/entities/         # Book, Category, Profile, ReadingProgress, Bookmark
test/
  core/                      # validators + Result unit tests
  widgets/                   # AppButton widget smoke test
```

---

## Configuration (env / dart-define)

Akuko needs your Supabase project URL and anon key. Resolution order is
**`--dart-define` first, then `.env`** (see `lib/core/config/env.dart`).

### Option A — `.env` file

```bash
cp .env.example .env
# edit .env and fill in AKUKO_SUPABASE_URL / AKUKO_SUPABASE_ANON_KEY
```

`.env` is git-ignored and bundled as an asset (declared in `pubspec.yaml`).

### Option B — `--dart-define`

```bash
flutter run \
  --dart-define=AKUKO_SUPABASE_URL=https://YOUR_REF.supabase.co \
  --dart-define=AKUKO_SUPABASE_ANON_KEY=YOUR_ANON_KEY
```

If neither source supplies the keys, the app boots into a friendly
"not configured" screen instead of crashing.

| Key                       | Description                                  |
| ------------------------- | -------------------------------------------- |
| `AKUKO_SUPABASE_URL`      | Supabase Project URL                         |
| `AKUKO_SUPABASE_ANON_KEY` | Supabase anon/public API key                 |
| `AKUKO_AUTH_REDIRECT`     | OAuth deep-link redirect (Google sign-in)    |

---

## Running the app

> Flutter is not bundled with this repo. Install the Flutter SDK (3.22+ / Dart
> 3.4+) first: <https://docs.flutter.dev/get-started/install>.

```bash
flutter pub get
flutter run            # add --dart-define flags or provide a .env
flutter test           # runs the example unit + widget tests
flutter analyze        # static analysis (analysis_options.yaml)
```

There is **no code generation step** — all Riverpod providers are hand-written,
so `build_runner` is not required.

### Admin dashboard (web)

Phase 1 operations console: [`admin/README.md`](admin/README.md). Vite + React app
using the same Supabase project (anon key + `profiles.is_admin`). Requires migrations
**0007 + 0008** for book workflow, publishers, feature flags, and analytics. See
[`admin/DEPLOY_VALIDATION.md`](admin/DEPLOY_VALIDATION.md). Not part of the Flutter `lib/` tree.

```bash
cd akuko && supabase db push
cd admin && cp .env.example .env.local && npm install && npm run dev
```

### Google sign-in setup

`AuthRemoteDataSource.signInWithGoogle` performs a native Google sign-in and
exchanges the ID token with Supabase (`signInWithIdToken`). You must configure
platform OAuth client IDs and (on Android/iOS) pass your **Web client ID** to
`GoogleSignIn(serverClientId: ...)`, and enable the Google provider in Supabase
Auth. On Web, prefer `signInWithOAuth` instead. See the Supabase social-login
docs.

---

## Supabase setup

Provision the schema, RLS policies, and storage buckets described in the
canonical spec. The backend (tables, policies, seed data, edge functions) is
owned separately — see [`docs/SUPABASE_SETUP.md`](docs/SUPABASE_SETUP.md) and
[`docs/CANONICAL_SPEC.md`](docs/CANONICAL_SPEC.md).

Storage buckets expected by the client:

- `book-files` (private) — EPUB/PDF, accessed via signed URLs (premium-gated)
- `book-covers` (public) — cover images
- `avatars` (public) — profile pictures

Table/column names referenced by the client live in `SupabaseTables`
(`lib/core/constants/app_constants.dart`).

---

## MVP vs roadmap

**MVP (Phase 1 — implemented):** auth (email/password + Google + forgot
password), profile + reading preferences, browse/search, categories,
featured/trending/new sections, book detail, EPUB+PDF reader shell with
font size / line spacing / Light-Dark-Sepia themes, reading progress, bookmarks,
and a light "continue reading" library.

**Phase 2+ (placeholders only):** highlights, notes, reviews, reading lists,
goals/streaks, subscriptions, AI summaries, TTS, offline sync, notifications,
admin. Each lives under `lib/features/<name>/` as a marked structural stub.

See [`docs/ROADMAP.md`](docs/ROADMAP.md) for the phased plan,
[`docs/API_DESIGN.md`](docs/API_DESIGN.md) for repository ↔ Supabase mappings,
and [`docs/CANONICAL_SPEC.md`](docs/CANONICAL_SPEC.md) for the authoritative data
contracts.
