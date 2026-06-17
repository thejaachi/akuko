<?php
/**
 * PSR-4 autoloader fallback when Composer vendor is not installed.
 *
 * @package Akuko\MobileApi
 */

namespace Akuko\MobileApi\Helpers;

defined( 'ABSPATH' ) || exit;

/**
 * Simple PSR-4 autoloader for Akuko\MobileApi namespace.
 */
final class Autoloader {

	/**
	 * @var string
	 */
	private static string $base_path = '';

	/**
	 * @var string
	 */
	private static string $plugin_path = '';

	/**
	 * Register autoloader.
	 *
	 * @param string $base_path Plugin includes path.
	 */
	public static function register( string $base_path ): void {
		self::$base_path   = rtrim( $base_path, '/\\' ) . DIRECTORY_SEPARATOR;
		self::$plugin_path = dirname( self::$base_path ) . DIRECTORY_SEPARATOR;
		spl_autoload_register( array( self::class, 'load' ) );
	}

	/**
	 * Load class file.
	 *
	 * @param string $class Fully qualified class name.
	 */
	public static function load( string $class ): void {
		$prefix = 'Akuko\\MobileApi\\';

		if ( ! str_starts_with( $class, $prefix ) ) {
			return;
		}

		$relative   = substr( $class, strlen( $prefix ) );
		$parts      = explode( '\\', $relative );
		$class_name = array_pop( $parts );

		$kebab     = strtolower( str_replace( '_', '-', $class_name ) );
		$file_name = 'class-' . $kebab . '.php';
		$paths     = array();

		if ( ! empty( $parts ) ) {
			$dir       = strtolower( implode( DIRECTORY_SEPARATOR, $parts ) );
			$paths[]   = self::$base_path . $dir . DIRECTORY_SEPARATOR . $file_name;
		} else {
			$paths[] = self::$base_path . $file_name;
			$paths[] = self::$base_path . 'class-akuko-' . $kebab . '.php';
		}

		if ( ! empty( $parts ) && 'Admin' === $parts[0] ) {
			$paths[] = self::$plugin_path . 'admin' . DIRECTORY_SEPARATOR . $file_name;
		}

		if ( ! empty( $parts ) && 'Database' === $parts[0] && isset( $parts[1] ) && 'Migrations' === $parts[1] ) {
			$paths[] = self::$plugin_path . 'database' . DIRECTORY_SEPARATOR . 'migrations' . DIRECTORY_SEPARATOR . '001_initial_schema.php';
		}

		if ( ! empty( $parts ) && 'Controllers' === $parts[0] ) {
			$paths[] = self::$base_path . 'controllers' . DIRECTORY_SEPARATOR . 'class-api-controllers.php';
		}

		foreach ( $paths as $path ) {
			if ( file_exists( $path ) ) {
				require_once $path;
				return;
			}
		}
	}
}
