<?php
/**
 * PHPUnit bootstrap.
 *
 * @package Akuko\MobileApi
 */

require_once dirname( __DIR__ ) . '/vendor/autoload.php';

if ( ! defined( 'ABSPATH' ) ) {
	define( 'ABSPATH', dirname( __DIR__ ) . '/tests/stubs/' );
}

require_once dirname( __DIR__ ) . '/tests/stubs/wp-error.php';
require_once dirname( __DIR__ ) . '/tests/stubs/wp-rest.php';
require_once dirname( __DIR__ ) . '/tests/stubs/wp-user.php';
require_once dirname( __DIR__ ) . '/tests/stubs/wp-google-auth.php';

if ( ! function_exists( '__' ) ) {
	function __( string $text, string $domain = 'default' ): string {
		return $text;
	}
}

require_once dirname( __DIR__ ) . '/includes/helpers/class-autoloader.php';
\Akuko\MobileApi\Helpers\Autoloader::register( dirname( __DIR__ ) . '/includes' );
