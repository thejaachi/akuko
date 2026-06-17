#!/usr/bin/env bash
#
# Build a production WordPress plugin zip with vendor/ included.
# Requires Composer only in environments that run this script (CI or server) — not on every developer PC.
#
# Usage: bash scripts/build-release.sh [version]
# Output: dist/akuko-mobile-api-production.zip (and dist/akuko-mobile-api-{version}.zip)
#
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PLUGIN_SLUG="akuko-mobile-api"
DIST="${ROOT}/dist"
STAGING="${DIST}/staging/${PLUGIN_SLUG}"

read_version() {
	if [[ -n "${1:-}" ]]; then
		echo "$1"
		return
	fi
	grep "define( 'AKUKO_MOBILE_API_VERSION'" "${ROOT}/akuko-mobile-api.php" \
		| sed -E "s/.*define\(\s*'AKUKO_MOBILE_API_VERSION',\s*'([^']+)'.*/\1/" \
		| head -n1
}

VERSION="$(read_version "${1:-}")"
ZIP_VERSIONED="${DIST}/${PLUGIN_SLUG}-${VERSION}.zip"
ZIP_PRODUCTION="${DIST}/${PLUGIN_SLUG}-production.zip"
VENDOR_AUTOLOAD="${ROOT}/vendor/autoload.php"

echo "Building ${PLUGIN_SLUG} release v${VERSION} ..."

if [[ ! -f "${VENDOR_AUTOLOAD}" ]]; then
	if command -v composer >/dev/null 2>&1; then
		echo "vendor/ missing — running composer install --no-dev ..."
		( cd "${ROOT}" && composer install --no-dev --optimize-autoloader --no-interaction )
	elif [[ -f "${ROOT}/composer.phar" ]] && command -v php >/dev/null 2>&1; then
		echo "vendor/ missing — running php composer.phar install --no-dev ..."
		( cd "${ROOT}" && php composer.phar install --no-dev --optimize-autoloader --no-interaction )
	else
		echo "ERROR: vendor/autoload.php is missing and Composer is not available." >&2
		echo "" >&2
		echo "Production zips must include vendor/. Options:" >&2
		echo "  - Run this script on CI (GitHub Actions) or a server with Composer" >&2
		echo "  - Run: bash bin/install-dependencies.sh" >&2
		echo "  - Download the artifact from .github/workflows/build-plugin-release.yml" >&2
		exit 1
	fi
fi

if [[ ! -f "${VENDOR_AUTOLOAD}" ]]; then
	echo "ERROR: vendor/autoload.php still missing after composer install." >&2
	exit 1
fi

rm -rf "${DIST}/staging"
mkdir -p "${STAGING}" "${DIST}"

rsync -a --delete \
	--exclude='.git/' \
	--exclude='.github/' \
	--exclude='tests/' \
	--exclude='scripts/' \
	--exclude='dist/' \
	--exclude='node_modules/' \
	--exclude='phpunit.xml.dist' \
	--exclude='.gitignore' \
	--exclude='composer.phar' \
	"${ROOT}/" "${STAGING}/"

if ! command -v zip >/dev/null 2>&1; then
	echo "ERROR: zip command not found." >&2
	exit 1
fi

rm -f "${ZIP_VERSIONED}" "${ZIP_PRODUCTION}"
( cd "${DIST}/staging" && zip -r "${ZIP_VERSIONED}" "${PLUGIN_SLUG}" -x "*.DS_Store" )

cp "${ZIP_VERSIONED}" "${ZIP_PRODUCTION}"
rm -rf "${DIST}/staging"

SIZE="$(du -h "${ZIP_PRODUCTION}" | cut -f1)"
echo "OK: ${ZIP_PRODUCTION} (${SIZE})"
echo "    vendor/ bundled: yes"
