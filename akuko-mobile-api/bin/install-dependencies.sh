#!/usr/bin/env bash
#
# Install production Composer dependencies for Akuko Mobile API.
# Run on the WordPress server after uploading the plugin (SSH or deploy hook).
#
# Usage: bash bin/install-dependencies.sh
# Exit: 0 = vendor ready, 1 = failure
#
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PLUGIN_DIR="$(cd "${SCRIPT_DIR}/.." && pwd)"
VENDOR_AUTOLOAD="${PLUGIN_DIR}/vendor/autoload.php"
COMPOSER_JSON="${PLUGIN_DIR}/composer.json"

if [[ -f "${VENDOR_AUTOLOAD}" ]]; then
	echo "OK: vendor/autoload.php already exists."
	exit 0
fi

if [[ ! -f "${COMPOSER_JSON}" ]]; then
	echo "ERROR: composer.json not found in ${PLUGIN_DIR}" >&2
	exit 1
fi

run_composer_install() {
	local composer_cmd=("$@")
	echo "Running: ${composer_cmd[*]} (in ${PLUGIN_DIR})"
	( cd "${PLUGIN_DIR}" && "${composer_cmd[@]}" install --no-dev --optimize-autoloader --no-interaction )
}

if command -v composer >/dev/null 2>&1; then
	run_composer_install composer
elif [[ -f "${PLUGIN_DIR}/composer.phar" ]] && command -v php >/dev/null 2>&1; then
	run_composer_install php "${PLUGIN_DIR}/composer.phar"
else
	echo "ERROR: Composer dependencies are not installed and Composer is not available." >&2
	echo "" >&2
	echo "Install Composer on this server, then re-run this script:" >&2
	echo "" >&2
	echo "  curl -sS https://getcomposer.org/installer | php" >&2
	echo "  php composer.phar install --no-dev --optimize-autoloader" >&2
	echo "" >&2
	echo "Or download a pre-built release zip (vendor included) from GitHub Actions." >&2
	echo "See docs/DISTRIBUTION.md in the plugin." >&2
	exit 1
fi

if [[ ! -f "${VENDOR_AUTOLOAD}" ]]; then
	echo "ERROR: composer install completed but vendor/autoload.php is still missing." >&2
	exit 1
fi

echo "OK: Production dependencies installed (firebase/php-jwt and autoloader)."
exit 0
