# Troubleshooting

## Plugin activation fails (fatal error)

### Symptom

WordPress shows a white screen or "Plugin could not be activated because it triggered a fatal error" when activating **Akuko Mobile API**.

### Common causes and fixes

| Cause | What you see | Fix |
|-------|----------------|-----|
| **Missing bootstrap classes** | `Class "Akuko\MobileApi\Plugin" not found` | Use a current release zip (1.0.0+ with autoloader fix). Do not upload a partial `includes/` copy without `class-akuko-plugin.php`. |
| **UTF-8 BOM in PHP files** | `Namespace declaration statement has to be the very first statement` | Re-download the production zip; interface files must not have a BOM before `<?php`. |
| **Missing `vendor/`** | Admin notice about JWT library (not a fatal on activate) | Upload a zip built with `vendor/` included, or run `bash bin/install-dependencies.sh` on the server. |
| **PHP version too old** | Parse errors on typed properties / `?self` | Upgrade to **PHP 8.1+**. |
| **WooCommerce inactive** | Plugin loads but REST API does not boot | Install and activate WooCommerce, then reload. Akuko defers boot until WooCommerce is available. |
| **Database migration error** | Activation message mentioning `dbDelta` or SQL | Confirm MySQL user can `CREATE TABLE`. Check `wp-content/debug.log` with `WP_DEBUG_LOG` enabled. |

### Enable WordPress debug logging

In `wp-config.php` (staging only):

```php
define( 'WP_DEBUG', true );
define( 'WP_DEBUG_LOG', true );
define( 'WP_DEBUG_DISPLAY', false );
```

Re-activate the plugin and inspect `wp-content/debug.log` for the exact class or file named in the stack trace.

### Verify zip layout before upload

The archive must use **forward slashes** and this entry:

```
akuko-mobile-api/akuko-mobile-api.php
```

Build with `scripts/build-release.ps1` (Windows) or GitHub Actions. Do not re-zip with Windows Explorer "Send to compressed folder" — that can break WordPress upload validation.

### Manual activation checklist

1. `wp-content/plugins/akuko-mobile-api/akuko-mobile-api.php` exists.
2. `includes/class-akuko-plugin.php` and `includes/class-akuko-container.php` exist.
3. `vendor/autoload.php` exists (for JWT authentication).
4. PHP **8.1+**, WordPress **6.4+**, WooCommerce active.
5. No duplicate copy of the plugin in `mu-plugins/` or a second folder name.

### Still stuck?

Capture the last 30 lines of `debug.log` during activation and the output of **Site Health → Info → Server** (PHP version, extensions).
