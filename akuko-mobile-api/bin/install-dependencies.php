<?php
/**
 * PHP-only fallback to install production Composer dependencies.
 *
 * Run from the plugin directory or anywhere:
 *   php bin/install-dependencies.php
 *
 * Exit codes: 0 = success, 1 = failure.
 *
 * @package Akuko\MobileApi
 */

if ( PHP_VERSION_ID < 80100 ) {
	fwrite( STDERR, "ERROR: PHP 8.1 or newer is required (found " . PHP_VERSION . ").\n" );
	exit( 1 );
}

$plugin_dir = dirname( __DIR__ );
$vendor     = $plugin_dir . '/vendor/autoload.php';
$composer   = $plugin_dir . '/composer.json';

if ( is_file( $vendor ) ) {
	echo "OK: vendor/autoload.php already exists.\n";
	exit( 0 );
}

if ( ! is_file( $composer ) ) {
	fwrite( STDERR, "ERROR: composer.json not found in {$plugin_dir}\n" );
	exit( 1 );
}

/**
 * Run a shell command and return exit code.
 *
 * @param string $command Command to execute.
 * @return int Exit code.
 */
function akuko_run_command( string $command ): int {
	echo "Running: {$command}\n";
	passthru( $command, $exit_code );
	return (int) $exit_code;
}

/**
 * Locate composer executable or phar.
 *
 * @param string $plugin_dir Plugin root path.
 * @return array{0: string, 1: string}|null Command prefix and install invocation, or null.
 */
function akuko_find_composer( string $plugin_dir ): ?array {
	$paths = explode( PATH_SEPARATOR, (string) getenv( 'PATH' ) );

	foreach ( $paths as $dir ) {
		if ( '' === $dir ) {
			continue;
		}
		$candidate = rtrim( $dir, DIRECTORY_SEPARATOR ) . DIRECTORY_SEPARATOR . 'composer' . ( 'WIN' === strtoupper( substr( PHP_OS, 0, 3 ) ) ? '.bat' : '' );
		if ( is_file( $candidate ) ) {
			return array( 'composer', 'composer' );
		}
	}

	$phar = $plugin_dir . '/composer.phar';
	if ( is_file( $phar ) ) {
		return array( PHP_BINARY, escapeshellarg( $phar ) );
	}

	return null;
}

/**
 * Download composer.phar into the plugin directory.
 *
 * @param string $plugin_dir Plugin root path.
 * @return bool True on success.
 */
function akuko_download_composer_phar( string $plugin_dir ): bool {
	$target = $plugin_dir . '/composer.phar';
	$url    = 'https://getcomposer.org/download/latest-stable/composer.phar';

	echo "Downloading Composer phar to {$target} ...\n";

	if ( function_exists( 'curl_init' ) ) {
		$fh = fopen( $target, 'wb' );
		if ( false === $fh ) {
			return false;
		}
		$ch = curl_init( $url );
		curl_setopt_array(
			$ch,
			array(
				CURLOPT_FILE           => $fh,
				CURLOPT_FOLLOWLOCATION => true,
				CURLOPT_FAILONERROR    => true,
				CURLOPT_TIMEOUT        => 120,
			)
		);
		$ok = curl_exec( $ch );
		curl_close( $ch );
		fclose( $fh );
		if ( false === $ok ) {
			@unlink( $target );
			return false;
		}
		return is_file( $target );
	}

	$context = stream_context_create(
		array(
			'http' => array(
				'timeout' => 120,
			),
		)
	);
	$data = @file_get_contents( $url, false, $context );
	if ( false === $data ) {
		return false;
	}
	return false !== file_put_contents( $target, $data );
}

$found = akuko_find_composer( $plugin_dir );

if ( null === $found ) {
	if ( ! akuko_download_composer_phar( $plugin_dir ) ) {
		fwrite( STDERR, "ERROR: Could not download composer.phar. Install Composer manually:\n" );
		fwrite( STDERR, "  curl -sS https://getcomposer.org/installer | php\n" );
		fwrite( STDERR, "  php composer.phar install --no-dev --optimize-autoloader\n" );
		fwrite( STDERR, "Or use a GitHub Actions release zip with vendor/ bundled.\n" );
		exit( 1 );
	}
	$found = array( PHP_BINARY, escapeshellarg( $plugin_dir . '/composer.phar' ) );
}

$cmd = sprintf(
	'%s %s install --no-dev --optimize-autoloader --no-interaction --working-dir=%s',
	$found[0],
	$found[1],
	escapeshellarg( $plugin_dir )
);

$exit = akuko_run_command( $cmd );

if ( 0 !== $exit ) {
	fwrite( STDERR, "ERROR: composer install failed (exit {$exit}).\n" );
	exit( 1 );
}

if ( ! is_file( $vendor ) ) {
	fwrite( STDERR, "ERROR: vendor/autoload.php is still missing after install.\n" );
	exit( 1 );
}

echo "OK: Production dependencies installed.\n";
exit( 0 );
