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
}
