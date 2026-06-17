# Akuko

**Akuko** is a digital reading ecosystem: a Flutter mobile app backed by a WordPress plugin (WooCommerce, Dokan, and custom REST endpoints). This monorepo contains the mobile client, the **Akuko Mobile API** WordPress plugin, and shared documentation.

**Live API:** https://books.ikikearts.com/wp-json/akuko/v1/  
**GitHub:** https://github.com/thejaachi/akuko

## Monorepo structure

| Path | Description |
|------|-------------|
| [`mobile-app/`](mobile-app/) | Flutter application (Android / iOS) — talks to the WordPress REST API |
| [`akuko-mobile-api/`](akuko-mobile-api/) | WordPress plugin: REST API, JWT auth, commerce hooks |
| [`docs/`](docs/) | Architecture, API reference, deployment, migration notes |
| [`.github/workflows/`](.github/workflows/) | CI: Flutter analyze/test, plugin PHPUnit |

There is **no Supabase runtime dependency** in the target architecture. Legacy Supabase folders under `mobile-app/` are being phased out; the app uses `lib/core/api/` against the WordPress backend.

## Getting started

### Prerequisites

- [Flutter](https://docs.flutter.dev/get-started/install) stable (SDK ≥ 3.4)
- For plugin work: PHP 8.2+, [Composer](https://getcomposer.org/)

### Mobile app

```bash
cd mobile-app
cp .env.example .env    # required for local runs and flutter analyze (file is gitignored)
flutter pub get
flutter run
```

Configure the API base URL in `.env` or via `--dart-define`:

```bash
flutter run --dart-define=AKUKO_API_BASE_URL=https://books.ikikearts.com/wp-json/akuko/v1/
```

See [`mobile-app/.env.example`](mobile-app/.env.example) for Paystack public keys and optional AI keys. Never commit `.env`.

**CI note:** GitHub Actions copies `.env.example` → `.env` before analyze and test.

### WordPress plugin (local / deploy)

```bash
cd akuko-mobile-api
composer install
composer test          # PHPUnit, when tests exist
```

**Deploy to WordPress:**

1. Run `composer install --no-dev --optimize-autoloader` (or use the release workflow).
2. Zip the `akuko-mobile-api/` folder (include `vendor/`).
3. Upload via WP Admin → Plugins → Add New → Upload, or deploy via FTP/SFTP.

Full steps: [`docs/mobile-api/INSTALLATION.md`](docs/mobile-api/INSTALLATION.md) and [`docs/mobile-api/DISTRIBUTION.md`](docs/mobile-api/DISTRIBUTION.md).

Tag `plugin-v*` on `main` to build a release zip via GitHub Actions (`akuko-mobile-api/.github/workflows/build-plugin-release.yml`).

## Documentation

- [docs/README.md](docs/README.md) — index
- [docs/mobile-api/API.md](docs/mobile-api/API.md) — REST endpoints
- [docs/mobile-app/ARCHITECTURE.md](docs/mobile-app/ARCHITECTURE.md) — Flutter architecture
- [docs/API_SMOKE_TEST.md](docs/API_SMOKE_TEST.md) — live API health check results

## Git workflow

| Branch | Purpose |
|--------|---------|
| `main` | Production-ready releases |
| `develop` | Integration branch — merge feature work here first |
| `feature/*` | Short-lived branches off `develop` |

**Flow:** `feature/…` → PR into `develop` → after QA, `develop` → `main`.

CI runs on push/PR to `develop` and `main` when paths under `mobile-app/` or `akuko-mobile-api/` change.

## Live API status (summary)

| Check | Status |
|-------|--------|
| `GET /books` | OK (200, catalog returned) |
| `POST /auth/login` without body | **Issue** — returns 500 instead of 400; see [docs/API_SMOKE_TEST.md](docs/API_SMOKE_TEST.md) |

## License

See component READMEs where applicable.
