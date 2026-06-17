# Phase 1 — Mobile Stability Report

**Branch:** `akuko-refactor-architecture`  
**Date:** 2026-06-04  
**Scope:** Flutter app at `akuko/` (`pubspec.yaml`, `lib/`, Supabase init, auth, books, reader, subscriptions, feature flags)

## Flutter SDK / analyze

| Check | Result |
|-------|--------|
| `flutter --version` | **Not available** — Flutter/Dart not on PATH; common install paths not found on this machine |
| `flutter pub get` | **Skipped** (no SDK) |
| `flutter analyze` | **Skipped** (no SDK) — **deployment blocker** for mobile CI/release on this host |
| `flutter run` | **Skipped** (no SDK / no device verification) |

**Gate status:** Analyze could not be run. Code inspection only; no compile-verified clean bill of health.

## Architecture inspection (read-only)

| Area | Status | Notes |
|------|--------|-------|
| Entry | OK | `main.dart` loads `.env`, shows config error UI if `Env.isConfigured` is false, then `Supabase.initialize` + Riverpod |
| Supabase | OK | `core/config/supabase_config.dart`, `core/network/supabase_client_provider.dart` |
| Auth | OK | GoTrue + Google via `features/auth/**` |
| Books | OK | Remote datasource + repository + providers |
| Reader | OK | `epub_view` + `pdfx` (`pdf_reader_view.dart`, EPUB views); progress via location strings |
| Subscriptions | OK | `PaystackService` invokes edge functions only (no secret in client) |
| Feature flags | OK | `SubscriptionGuard` combines `Entitlements` + `FeatureFlagSnapshot` |
| Premium server | OK | `is_premium()` in `0006_subscriptions.sql`; guard is client UX only |

## Runtime risks

1. **Missing `.env` at runtime** — App shows `_ConfigErrorApp` without `AKUKO_SUPABASE_URL` / `AKUKO_SUPABASE_ANON_KEY`.
2. **Bundled `.env` in assets** — `pubspec.yaml` lists `.env`; ensure production builds use `--dart-define` and do not ship secrets.
3. **Reader fonts** — Bundled Literata fonts commented out; relies on `google_fonts` (network at runtime).
4. **PDF reader** — Downloads full file via HTTP into memory (`pdfx`); large files may OOM on low-end devices.
5. **Paystack checkout** — WebView + server verify; client must not treat redirect alone as success (implemented correctly in `PaystackService`).

## Dependencies (`pubspec.yaml`)

All declared deps are standard and aligned with features: `supabase_flutter`, `epub_view`, `pdfx`, `webview_flutter`, `flutter_riverpod`, `go_router`, etc. No missing path imports found in spot checks.

## Code-level fixes this phase

No Dart compile errors were identified without `flutter analyze`. No API keys added.

## Launch verification

**Not verified** on device (Flutter SDK absent).

## Recommendation

Run on a machine with Flutter ≥3.22:

```bash
cd akuko
flutter pub get
flutter analyze
flutter run
```

Proceed to Phase 2+ on this repo; treat mobile build/signing as **blocked on this CI host** until SDK is installed.

## Follow-up retry

**When:** 2026-06-04 (Windows unblock retry)

| Check | Result |
|-------|--------|
| Flutter on PATH | **No** (`where.exe flutter` — not found) |
| `C:\src\flutter\bin\flutter.bat` | Absent |
| `C:\flutter\bin\flutter.bat` | Absent |
| `winget list --id Google.Flutter` | Not installed |
| `winget install -e --id Google.Flutter` | **Failed** — ID not in catalog (`No package found matching input criteria`; `winget search flutter` lists apps tagged flutter, not the Flutter SDK) |
| `flutter doctor -v` | Not run (SDK missing) |
| `flutter pub get` | Not run |
| `flutter analyze` | Not run — error count **N/A** |
| `flutter build apk --release` | **No** |

**Doctor summary:** N/A (Flutter SDK unavailable).

**Remediation:** Install Flutter per [official Windows guide](https://docs.flutter.dev/get-started/install/windows) (e.g. clone/zip to `C:\src\flutter`, add `%FLUTTER_ROOT%\bin` to user PATH). Winget `Google.Flutter` is not offered on this machine's sources.


## Manual Flutter install verification

**When:** 2026-06-04 (user-installed SDK at `C:\Users\HP\flutter`)

| Check | Result |
|-------|--------|
| `where.exe flutter` | `C:\Users\HP\flutter\bin\flutter.bat` (PATH must include `C:\Users\HP\flutter\bin` and Git) |
| `flutter --version` | **Flutter 3.44.1** (stable), Dart **3.12.1**, DevTools 2.57.0 |
| `flutter doctor -v` | Flutter OK; **Android toolchain: NO** (Android SDK not found); Chrome OK; VS Windows apps: NO |
| `flutter pub get` | **Success** (139 dependencies changed) |
| `flutter analyze` (before fixes) | **6 errors**, 1 warning, 14 info (21 issues) |
| `flutter analyze` (after fixes) | **0 errors**, 0 warnings, 16 info |
| `flutter build apk --release` | **Failed** � no Android SDK |

**Analyzer fixes (`lib/**`):** `app_router.dart` (material import), `app_theme.dart` (`CardThemeData`), `extensions.dart` (`screenHeight`), `epub_reader_view.dart` (async EPUB download), `reader_page.dart` (unused import).

**Remediation for device builds:** Install Android Studio / SDK, set `ANDROID_HOME`, then re-run release APK/AAB.
