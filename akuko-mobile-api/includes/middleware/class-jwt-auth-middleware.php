<?php
/**
 * JWT authentication middleware.
 *
 * @package Akuko\MobileApi
 */

namespace Akuko\MobileApi\Middleware;

use Akuko\MobileApi\Services\Interfaces\AuthenticationService_Interface;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

defined( 'ABSPATH' ) || exit;

/**
 * JWT middleware for REST API.
 */
final class Jwt_Auth_Middleware {

	public function __construct(
		private AuthenticationService_Interface $auth_service
	) {}

	/**
	 * Validate Bearer token and set current user.
	 *
	 * @param \WP_REST_Request $request Request.
	 * @return bool|\WP_Error
	 */
	public function authenticate( \WP_REST_Request $request ): bool|\WP_Error {
		$header = $request->get_header( 'authorization' );

		if ( empty( $header ) || ! preg_match( '/Bearer\s+(\S+)/i', $header, $matches ) ) {
			return new \WP_Error( 'akuko_unauthorized', __( 'Authorization header required.', 'akuko-mobile-api' ), array( 'status' => 401 ) );
		}

		try {
			$payload = $this->auth_service->validate_access_token( $matches[1] );
			$user_id = (int) ( $payload->sub ?? 0 );

			if ( $user_id <= 0 ) {
				return new \WP_Error( 'akuko_invalid_token', __( 'Invalid token.', 'akuko-mobile-api' ), array( 'status' => 401 ) );
			}

			wp_set_current_user( $user_id );
			$request->set_param( '_akuko_user_id', $user_id );

			return true;
		} catch ( \Exception $e ) {
			return new \WP_Error( 'akuko_invalid_token', $e->getMessage(), array( 'status' => 401 ) );
		}
	}

	/**
	 * Optional auth — does not fail if no token.
	 *
	 * @param \WP_REST_Request $request Request.
	 * @return bool
	 */
	public function optional_authenticate( \WP_REST_Request $request ): bool {
		$result = $this->authenticate( $request );
		return true === $result || $result instanceof \WP_Error;
	}
}
