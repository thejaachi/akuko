#Requires -Version 5.1
<#
.SYNOPSIS
    Build a production WordPress plugin zip with vendor/ included.

.DESCRIPTION
    Requires Composer only where this script runs (CI or server), not on every developer PC.
    Output: dist/akuko-mobile-api-production.zip

.PARAMETER Version
    Optional version string; defaults to AKUKO_MOBILE_API_VERSION from the plugin bootstrap.
#>
param(
    [string]$Version = ''
)

$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$PluginSlug = 'akuko-mobile-api'
$Dist = Join-Path $Root 'dist'
$Staging = Join-Path $Dist "staging\$PluginSlug"
$VendorAutoload = Join-Path $Root 'vendor\autoload.php'

function Get-PluginVersion {
    param([string]$Override)
    if ($Override) { return $Override }
    $line = Select-String -Path (Join-Path $Root 'akuko-mobile-api.php') -Pattern "AKUKO_MOBILE_API_VERSION" | Select-Object -First 1
    if ($line -match "define\(\s*'AKUKO_MOBILE_API_VERSION',\s*'([^']+)'") { return $Matches[1] }
    return '0.0.0'
}

$Version = Get-PluginVersion -Override $Version
$ZipVersioned = Join-Path $Dist "$PluginSlug-$Version.zip"
$ZipProduction = Join-Path $Dist "$PluginSlug-production.zip"

Write-Host "Building $PluginSlug release v$Version ..."

if (-not (Test-Path $VendorAutoload)) {
    $composer = Get-Command composer -ErrorAction SilentlyContinue
    $php = Get-Command php -ErrorAction SilentlyContinue
    $phar = Join-Path $Root 'composer.phar'

    if ($composer) {
        Write-Host 'vendor/ missing — running composer install --no-dev ...'
        Push-Location $Root
        try {
            & composer install --no-dev --optimize-autoloader --no-interaction
        } finally {
            Pop-Location
        }
    } elseif ((Test-Path $phar) -and $php) {
        Write-Host 'vendor/ missing — running php composer.phar install --no-dev ...'
        Push-Location $Root
        try {
            & php $phar install --no-dev --optimize-autoloader --no-interaction
        } finally {
            Pop-Location
        }
    } else {
        Write-Error @"
vendor/autoload.php is missing and Composer is not available.

Production zips must include vendor/. Options:
  - Run this script on CI (GitHub Actions) or a server with Composer
  - Run: bash bin/install-dependencies.sh
  - Download the artifact from GitHub Actions (build-plugin-release workflow)
"@
    }
}

if (-not (Test-Path $VendorAutoload)) {
    throw 'vendor/autoload.php still missing after composer install.'
}

if (Test-Path (Join-Path $Dist 'staging')) {
    Remove-Item (Join-Path $Dist 'staging') -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $Staging | Out-Null

$excludeDirs = @('.git', '.github', 'tests', 'scripts', 'dist', 'node_modules')
$excludeFiles = @('phpunit.xml.dist', '.gitignore', 'composer.phar')

robocopy $Root $Staging /E /NFL /NDL /NJH /NJS /NC /NS /NP `
    /XD $excludeDirs `
    /XF $excludeFiles | Out-Null
if ($LASTEXITCODE -ge 8) { throw "robocopy failed with exit code $LASTEXITCODE" }

foreach ($zip in @($ZipVersioned, $ZipProduction)) {
    if (Test-Path $zip) { Remove-Item $zip -Force }
}

# WordPress requires zip entries with forward slashes (akuko-mobile-api/akuko-mobile-api.php).
# Compress-Archive uses backslashes and triggers "Plugin file does not exist" on upload.
$stagingParent = Split-Path $Staging -Parent
Push-Location $stagingParent
try {
    & tar -a -cf $ZipVersioned $PluginSlug
    if ($LASTEXITCODE -ne 0) { throw "tar failed with exit code $LASTEXITCODE" }
} finally {
    Pop-Location
}

Copy-Item $ZipVersioned $ZipProduction -Force
Remove-Item (Join-Path $Dist 'staging') -Recurse -Force

Add-Type -AssemblyName System.IO.Compression.FileSystem
$archive = [System.IO.Compression.ZipFile]::OpenRead($ZipProduction)
try {
    $mainEntry = 'akuko-mobile-api/akuko-mobile-api.php'
    $hasMain = $archive.Entries | Where-Object { $_.FullName -eq $mainEntry }
    if (-not $hasMain) {
        $sample = ($archive.Entries | Select-Object -First 5 | ForEach-Object { $_.FullName }) -join ', '
        throw "Zip layout invalid: missing $mainEntry. First entries: $sample"
    }
    $backslashes = @($archive.Entries | Where-Object { $_.FullName -match '\\' })
    if ($backslashes.Count -gt 0) {
        throw "Zip layout invalid: $($backslashes.Count) entries use backslashes (WordPress requires forward slashes)."
    }
} finally {
    $archive.Dispose()
}

$sizeMb = [math]::Round((Get-Item $ZipProduction).Length / 1MB, 2)
Write-Host "OK: $ZipProduction ($sizeMb MB)"
Write-Host '    vendor/ bundled: yes'
Write-Host "    verified: $mainEntry"
