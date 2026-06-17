# Installation

## Requirements

- **WordPress** 6.4 or newer
- **PHP** 8.1 or newer (with `json`, `mbstring`, and `openssl` extensions)
- **WooCommerce** installed and active
- **JWT library** (`vendor/`, including `firebase/php-jwt`) must be present before authentication works

You **do not** need Composer on your development PC. Use one of the deployment paths below.

## Production deployment paths (no local Composer)

| Path | Who runs Composer | Steps |
|------|-------------------|-------|
| **GitHub Actions artifact** | CI only | Tag `plugin-v*` → download `akuko-mobile-api-release.zip` → WP Admin → Plugins → Upload |
| **Server SSH** | Server | Upload plugin → `bash bin/install-dependencies.sh` → activate |
| **Pre-built dist zip** | Already bundled | Upload `dist/akuko-mobile-api-production.zip` (built on CI/server) |

See [DISTRIBUTION.md](DISTRIBUTION.md) for build and artifact details.

## Distribution ZIP (WordPress Admin)

1. Download `akuko-mobile-api-release.zip` from GitHub Actions, **or** use `dist/akuko-mobile-api-production.zip` from a CI/server build.
2. WordPress Admin → **Plugins** → **Add New** → **Upload Plugin**.
3. Choose the zip → **Install Now** → **Activate Plugin**.

Confirm the zip contains `vendor/autoload.php` inside the `akuko-mobile-api/` folder before uploading.

## FTP / SFTP

1. Upload the release zip to the server (for example under `wp-content/plugins/`).
2. Unzip so the plugin lives at `wp-content/plugins/akuko-mobile-api/` (`akuko-mobile-api.php` at that folder root).
3. If `vendor/` is **not** in the upload, SSH into the plugin directory and run:

   ```bash
   bash bin/install-dependencies.sh
   ```

   Or:

   ```bash
   php bin/install-dependencies.php
   ```

4. WordPress Admin → **Plugins** → activate **Akuko Mobile API**.

## Deploy from Git (server)

```bash
cd wp-content/plugins
git clone <repo> akuko-mobile-api
cd akuko-mobile-api
bash bin/install-dependencies.sh
```

Composer runs on the **server**, not on your laptop.

## Activate

WordPress Admin → Plugins → Activate **Akuko Mobile API**

Activation runs `001_initial_schema.php` and creates custom tables. If `vendor/` is missing, an admin notice explains how to install dependencies.

## Configure Secrets

After activation, add to `wp-config.php` (above "That's all, stop editing!"):

```php
/** Akuko Mobile API */
define( 'AKUKO_JWT_SECRET', 'generate-a-64-character-random-string-here' );
define( 'AKUKO_PAYSTACK_SECRET_KEY', 'sk_live_your_paystack_secret' );
define( 'AKUKO_DOWNLOAD_SIGNING_KEY', 'another-random-64-char-string' );
```

Alternatively, Paystack secret can be stored via:
`update_option( 'akuko_paystack_secret_key', 'sk_...' );` — wp-config is preferred.

## Verify

```bash
curl https://books.ikikearts.com/wp-json/akuko/v1/settings
curl https://books.ikikearts.com/wp-json/akuko/v1/books?per_page=5
```

## Admin Settings

**Akuko Mobile → Settings** — support email, premium price display.

**Akuko Mobile → Feature Flags** — toggle mobile features.

## Flutter Integration

Point the Flutter app's API client to:

```text
https://books.ikikearts.com/wp-json/akuko/v1
```

See [ARCHITECTURE.md](ARCHITECTURE.md) for auth and download flows.

## Troubleshooting

| Issue | Fix |
|-------|-----|
| 404 on API routes | Re-save Permalinks (Settings → Permalinks) |
| WooCommerce notice | Ensure WooCommerce is active |
| Paystack verify fails | Check `AKUKO_PAYSTACK_SECRET_KEY` |
| Plugin could not load JWT library | Run `bash bin/install-dependencies.sh` or `php bin/install-dependencies.php` on the server; or upload a zip with `vendor/` from GitHub Actions |
| JWT errors | Ensure `AKUKO_JWT_SECRET` is set; ensure `vendor/autoload.php` exists |
| Class not found / autoload errors | Install dependencies on the server or use a pre-built release zip |
