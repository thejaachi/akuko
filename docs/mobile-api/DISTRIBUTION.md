# Distribution — building the WordPress zip

This plugin installs as folder `akuko-mobile-api` under `wp-content/plugins/`. Release zips must use that folder name at the **root** of the archive.

**You do not need Composer on your local PC** for production deployment. Composer runs in CI or on the WordPress server (see paths below).

## Production deployment paths (no local Composer)

| Path | Who runs Composer | Steps |
|------|-------------------|-------|
| **GitHub Actions artifact** | CI only | Tag `plugin-v*` (or run workflow manually) → download `akuko-mobile-api-release.zip` → WP Admin upload |
| **Server SSH** | Server | Upload plugin → `bash bin/install-dependencies.sh` (or `php bin/install-dependencies.php`) → activate |
| **Pre-built dist zip** | Already bundled | Run `scripts/build-release.sh` on CI/server → upload `dist/akuko-mobile-api-production.zip` |

## GitHub Actions (recommended)

Workflow: [`.github/workflows/build-plugin-release.yml`](../.github/workflows/build-plugin-release.yml)

**Triggers:**

- Push a tag matching `plugin-v*` (for example `plugin-v1.0.0`)
- Manual **workflow_dispatch** from the Actions tab

**Result:** Artifact `akuko-mobile-api-release.zip` with `vendor/` included. Download from the workflow run — **no local Composer required**.

```text
akuko-mobile-api-production.zip
└── akuko-mobile-api/              ← exactly one folder at zip root
    ├── akuko-mobile-api.php       ← main bootstrap (Plugin Name header)
    ├── vendor/                    ← firebase/php-jwt bundled
    │   └── autoload.php
    ├── bin/
    ├── includes/
    └── ...
```

Zip entry paths must use **forward slashes** (`akuko-mobile-api/akuko-mobile-api.php`). Archives built with PowerShell `Compress-Archive` use backslashes and WordPress reports **"Plugin file does not exist"** — use `scripts/build-release.ps1` (tar-based) or `scripts/build-release.sh` / GitHub Actions instead.

## Server-side install (FTP / manual deploy)

After uploading the plugin folder **without** `vendor/`:

```bash
cd wp-content/plugins/akuko-mobile-api
bash bin/install-dependencies.sh
```

PHP-only fallback (downloads Composer phar if needed):

```bash
php bin/install-dependencies.php
```

Requires PHP 8.1+ CLI on the server. If Composer is not in `PATH`, the shell script prints install instructions (`curl` installer from getcomposer.org).

## Build scripts (CI or server with Composer)

From the plugin root, on Linux/macOS or WSL:

```bash
bash scripts/build-release.sh
```

Windows (PowerShell):

```powershell
.\scripts\build-release.ps1
```

Outputs:

- `dist/akuko-mobile-api-production.zip` — canonical production artifact
- `dist/akuko-mobile-api-{version}.zip` — same contents, versioned name

The script runs `composer install --no-dev` when Composer is available, then fails with a clear message if `vendor/` is still missing.

## Vendor directory policy

`vendor/` is **not** committed to git (see `.gitignore`). Production dependencies are delivered by:

1. CI-built release zip (artifact), or
2. `bin/install-dependencies.sh` / `bin/install-dependencies.php` on the server, or
3. `scripts/build-release.*` on any machine that has Composer (typically CI, not every developer laptop)

## Verify before upload

- Unzip and confirm `akuko-mobile-api/akuko-mobile-api.php` exists
- Confirm `akuko-mobile-api/vendor/autoload.php` exists
- Upload via [INSTALLATION.md](INSTALLATION.md) (WP Admin or FTP)

## Troubleshooting

| Issue | Fix |
|-------|-----|
| **Plugin file does not exist** (WP Admin upload) | Rebuild with `scripts/build-release.ps1` or `.sh` — do not use `Compress-Archive`. Unzip locally and confirm `akuko-mobile-api/akuko-mobile-api.php` at the root folder (not double-nested, not loose files at zip root). Search plugins for **Akuko Mobile API**. |
| Plugin could not load JWT library | Run `bash bin/install-dependencies.sh` on the server, or use a CI-built zip with `vendor/` |
| Build script fails: vendor missing | Run on a host with Composer, or download the GitHub Actions artifact |
| `composer: command not found` (server) | Install Composer via [getcomposer.org](https://getcomposer.org/download/) or use `php bin/install-dependencies.php` |

## Legacy manual zip (optional)

If you already have Composer on a build host, you can still zip manually after `composer install --no-dev`. Prefer `scripts/build-release.sh` or GitHub Actions for consistent excludes and layout.
