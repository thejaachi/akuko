# Akuko Mobile API

Production-grade BFF (Backend-for-Frontend) WordPress plugin for the [Akuko](https://books.ikikearts.com) Flutter mobile app.

## Quick Start

1. Copy `akuko-mobile-api/` to `wp-content/plugins/` (use a [GitHub Actions release zip](docs/DISTRIBUTION.md) with `vendor/` included, or run `bash bin/install-dependencies.sh` on the server)
2. Activate **Akuko Mobile API** in WordPress admin
3. Add secrets to `wp-config.php`:

```php
define( 'AKUKO_JWT_SECRET', 'your-64-char-secret' );
define( 'AKUKO_PAYSTACK_SECRET_KEY', 'sk_live_...' );
define( 'AKUKO_DOWNLOAD_SIGNING_KEY', 'your-download-signing-key' );
```

4. API base: `https://books.ikikearts.com/wp-json/akuko/v1/`

## Requirements

- PHP 8.1+
- WordPress 6.4+
- WooCommerce 8+
- Dokan (optional, for author/vendor data)
- Paystack WooCommerce plugin (existing integration)

## Architecture

Layered design: **Controllers → Services → Repositories → WordPress/WooCommerce**

See [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) for diagrams and design decisions.

## API Documentation

Full endpoint reference: [docs/API.md](docs/API.md)

## Development

```bash
composer install
composer test
```

## Admin

WordPress admin menu: **Akuko Mobile** — Dashboard, API Monitor, Premium Members, Feature Flags, Settings, Logs.

## License

GPL-2.0-or-later
