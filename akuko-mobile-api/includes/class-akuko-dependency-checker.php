<?php
/**
 * Warn administrators when Composer vendor dependencies are missing.
 *
 * @package Akuko\MobileApi
 */

namespace Akuko\MobileApi;

defined( 'ABSPATH' ) || exit;

/**
 * Checks for vendor/autoload.php and shows a dismissible admin notice.
 */
final class Dependency_Checker {

	private const OPTION_VENDOR_MISSING = 'akuko_mobile_api_vendor_missing';
	private const NOTICE_DISMISSED      = 'akuko_mobile_api_vendor_notice_dismissed';

	/**
	 * Register hooks.
	 */
	public static function register(): void {
		add_action( 'admin_init', array( self::class, 'maybe_clear_flags' ) );
		add_action( 'admin_notices', array( self::class, 'render_notice' ) );
		add_action( 'wp_ajax_akuko_dismiss_vendor_notice', array( self::class, 'dismiss_notice' ) );
	}

	/**
	 * Flag missing vendor on activation (called from Plugin::activate).
	 */
	public static function flag_if_missing(): void {
		if ( self::vendor_ready() ) {
			delete_option( self::OPTION_VENDOR_MISSING );
			return;
		}

		update_option( self::OPTION_VENDOR_MISSING, '1', false );
		delete_option( self::NOTICE_DISMISSED );
	}

	/**
	 * Clear flags once vendor is present.
	 */
	public static function maybe_clear_flags(): void {
		if ( self::vendor_ready() ) {
			delete_option( self::OPTION_VENDOR_MISSING );
			delete_option( self::NOTICE_DISMISSED );
		}
	}

	/**
	 * Render admin notice when JWT library is unavailable.
	 */
	public static function render_notice(): void {
		if ( ! current_user_can( 'activate_plugins' ) ) {
			return;
		}

		if ( self::vendor_ready() ) {
			return;
		}

		if ( get_option( self::NOTICE_DISMISSED ) ) {
			return;
		}

		$install_sh  = AKUKO_MOBILE_API_PATH . 'bin/install-dependencies.sh';
		$install_php = AKUKO_MOBILE_API_PATH . 'bin/install-dependencies.php';
		$docs        = AKUKO_MOBILE_API_PATH . 'docs/DISTRIBUTION.md';

		$message = esc_html__(
			'Akuko Mobile API could not load the JWT library (firebase/php-jwt). Authentication will not work until production dependencies are installed.',
			'akuko-mobile-api'
		);

		$steps = array();

		if ( is_readable( $install_sh ) ) {
			$steps[] = sprintf(
				/* translators: %s: shell command */
				esc_html__( 'SSH: run %s in the plugin directory', 'akuko-mobile-api' ),
				'<code>bash bin/install-dependencies.sh</code>'
			);
		}

		if ( is_readable( $install_php ) ) {
			$steps[] = sprintf(
				/* translators: %s: php command */
				esc_html__( 'Or run %s (downloads Composer phar if needed)', 'akuko-mobile-api' ),
				'<code>php bin/install-dependencies.php</code>'
			);
		}

		$steps[] = esc_html__(
			'Or upload a pre-built release zip from GitHub Actions (vendor included).',
			'akuko-mobile-api'
		);

		if ( is_readable( $docs ) ) {
			$steps[] = sprintf(
				/* translators: %s: documentation filename */
				esc_html__( 'See %s for all deployment paths.', 'akuko-mobile-api' ),
				'<code>docs/DISTRIBUTION.md</code>'
			);
		}

		$dismiss_url = wp_nonce_url(
			admin_url( 'admin-ajax.php?action=akuko_dismiss_vendor_notice' ),
			'akuko_dismiss_vendor_notice'
		);

		printf(
			'<div class="notice notice-error is-dismissible" data-akuko-vendor-notice="1"><p><strong>%s</strong></p><ul style="list-style:disc;margin-left:1.5em;">%s</ul><p><a href="%s">%s</a></p></div>',
			$message,
			implode(
				'',
				array_map(
					static fn( string $item ): string => '<li>' . $item . '</li>',
					$steps
				)
			),
			esc_url( $dismiss_url ),
			esc_html__( 'Dismiss this notice', 'akuko-mobile-api' )
		);
	}

	/**
	 * AJAX handler to dismiss the notice.
	 */
	public static function dismiss_notice(): void {
		check_ajax_referer( 'akuko_dismiss_vendor_notice' );

		if ( ! current_user_can( 'activate_plugins' ) ) {
			wp_die( esc_html__( 'Unauthorized.', 'akuko-mobile-api' ), 403 );
		}

		update_option( self::NOTICE_DISMISSED, '1', false );
		wp_send_json_success();
	}

	/**
	 * Whether vendor/autoload.php exists.
	 */
	public static function vendor_ready(): bool {
		return is_readable( AKUKO_MOBILE_API_PATH . 'vendor/autoload.php' );
	}
}
