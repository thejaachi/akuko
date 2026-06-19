<?php
namespace Akuko\MobileApi\Helpers;

defined( 'ABSPATH' ) || exit;

/**
 * Auth-related feature flags (wp-config.php constants).
 */
final class Auth_Config {

	/**
	 * When true (default), mobile registration does not send WordPress new-user
	 * emails and login is allowed immediately without email confirmation.
	 */
	public static function skip_email_verification(): bool {
		if ( defined( 'AKUKO_SKIP_EMAIL_VERIFICATION' ) ) {
			return (bool) AKUKO_SKIP_EMAIL_VERIFICATION;
		}

		return true;
	}

	/**
	 * Allowed Google OAuth client IDs (Android + Web) for ID token `aud` checks.
	 *
	 * Define in wp-config.php as a comma-separated string or PHP array:
	 *   define( 'AKUKO_GOOGLE_CLIENT_ID', 'android-client.apps.googleusercontent.com,web-client.apps.googleusercontent.com' );
	 *
	 * @return string[]
	 */
	public static function google_client_ids(): array {
		if ( defined( 'AKUKO_GOOGLE_CLIENT_ID' ) ) {
			$raw = AKUKO_GOOGLE_CLIENT_ID;
			if ( is_array( $raw ) ) {
				return array_values( array_filter( array_map( 'trim', $raw ) ) );
			}

			return array_values(
				array_filter(
					array_map( 'trim', explode( ',', (string) $raw ) )
				)
			);
		}

		$option = get_option( 'akuko_google_client_ids', '' );
		if ( is_string( $option ) && '' !== $option ) {
			return array_values(
				array_filter(
					array_map( 'trim', explode( ',', $option ) )
				)
			);
		}

		return array();
	}
}
