# Akuko

**Akuko** is a digital reading ecosystem: a Flutter mobile app backed by a WordPress plugin (WooCommerce, Dokan, and custom REST endpoints). This repository is a monorepo; there is no Supabase runtime dependency in the target architecture—the mobile app talks to the WordPress **Akuko Mobile API** plugin.

## Repository layout

| Path | Description |
|------|-------------|
| `mobile-app/` | Flutter application (Android / iOS) |
| `akuko-mobile-api/` | WordPress plugin: REST API, auth, commerce hooks |
| `docs/` | Architecture, API, deployment, and migration documentation |

## Getting started

### Mobile app

```bash
cd mobile-app
flutter pub get
flutter run
```

Copy `mobile-app/.env.example` to `mobile-app/.env` and set API base URL and public keys (never commit `.env`).

### WordPress plugin

Install dependencies with Composer from `akuko-mobile-api/` (see `docs/mobile-api/INSTALLATION.md`), then deploy the plugin to your WordPress site.

## Branches

- `main` — stable releases
- `develop` — integration branch

## License

See component READMEs where applicable.
