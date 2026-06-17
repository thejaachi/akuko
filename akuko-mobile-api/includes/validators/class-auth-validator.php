<?php
namespace Akuko\MobileApi\Validators;

defined( 'ABSPATH' ) || exit;

class Auth_Validator {
	public static function registration( array $data ): ?string {
		if ( empty( $data['email'] ) || ! is_email( $data['email'] ) ) {
			return __( 'Valid email is required.', 'akuko-mobile-api' );
		}
		if ( empty( $data['password'] ) || strlen( $data['password'] ) < 8 ) {
			return __( 'Password must be at least 8 characters.', 'akuko-mobile-api' );
		}
		return null;
	}
}
