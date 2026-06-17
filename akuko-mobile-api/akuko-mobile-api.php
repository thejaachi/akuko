<?php
/**
 * Plugin Name:       Akuko Mobile API
 * Plugin URI:        https://books.ikikearts.com
 * Description:       Production BFF REST API for the Akuko Flutter mobile app. Abstracts WooCommerce, Dokan, and Paystack.
 * Version:           1.0.0
 * Requires at least: 6.4
 * Requires PHP:      8.1
 * Author:            Ikike Arts
 * Author URI:        https://ikikearts.com
 * License:           GPL-2.0-or-later
 * License URI:       https://www.gnu.org/licenses/gpl-2.0.html
 * Text Domain:       akuko-mobile-api
 * Domain Path:       /languages
 *
 * @package Akuko\MobileApi
 */

defined( 'ABSPATH' ) || exit;

define( 'AKUKO_MOBILE_API_VERSION', '1.0.0' );
define( 'AKUKO_MOBILE_API_FILE', __FILE__ );
define( 'AKUKO_MOBILE_API_PATH', plugin_dir_path( __FILE__ ) );
define( 'AKUKO_MOBILE_API_URL', plugin_dir_url( __FILE__ ) );
define( 'AKUKO_MOBILE_API_BASENAME', plugin_basename( __FILE__ ) );

$akuko_autoload = AKUKO_MOBILE_API_PATH . 'vendor/autoload.php';
if ( file_exists( $akuko_autoload ) ) {
	require_once $akuko_autoload;
}

require_once AKUKO_MOBILE_API_PATH . 'includes/helpers/class-autoloader.php';
require_once AKUKO_MOBILE_API_PATH . 'database/migrations/001_initial_schema.php';
require_once AKUKO_MOBILE_API_PATH . 'includes/class-akuko-dependency-checker.php';
require_once AKUKO_MOBILE_API_PATH . 'includes/class-akuko-container.php';
require_once AKUKO_MOBILE_API_PATH . 'includes/class-akuko-plugin.php';
\Akuko\MobileApi\Helpers\Autoloader::register( AKUKO_MOBILE_API_PATH . 'includes' );

\Akuko\MobileApi\Dependency_Checker::register();

register_activation_hook(
	__FILE__,
	static function (): void {
		try {
			\Akuko\MobileApi\Plugin::activate();
		} catch ( \Throwable $e ) {
			if ( function_exists( 'deactivate_plugins' ) ) {
				deactivate_plugins( AKUKO_MOBILE_API_BASENAME );
			}

			wp_die(
				esc_html(
					sprintf(
						/* translators: %s: error message */
						__( 'Akuko Mobile API could not be activated: %s', 'akuko-mobile-api' ),
						$e->getMessage()
					)
				),
				esc_html__( 'Plugin Activation Error', 'akuko-mobile-api' ),
				array( 'back_link' => true )
			);
		}
	}
);
register_deactivation_hook( __FILE__, array( 'Akuko\MobileApi\Plugin', 'deactivate' ) );

add_action(
	'plugins_loaded',
	static function (): void {
		if ( ! class_exists( 'WooCommerce' ) ) {
			add_action(
				'admin_notices',
				static function (): void {
					printf(
						'<div class="notice notice-error"><p>%s</p></div>',
						esc_html__( 'Akuko Mobile API requires WooCommerce to be installed and active.', 'akuko-mobile-api' )
					);
				}
			);
			return;
		}

		\Akuko\MobileApi\Plugin::instance()->boot();
	},
	20
);
