<?php
/**
 * Transient-based rate limiting middleware.
 *
 * @package Akuko\MobileApi
 */

namespace Akuko\MobileApi\Middleware;

defined( 'ABSPATH' ) || exit;

/**
 * Rate limiter per IP address.
 */
final class Rate_Limit_Middleware {

	private const LIMIT  = 120;
	private const WINDOW = 60;

	/**
	 * Check rate limit.
	 *
	 * @param \WP_REST_Request $request Request.
	 * @return bool|\WP_Error
	 */
	public function check( \WP_REST_Request $request ): bool|\WP_Error {
		$ip  = $this->get_client_ip();
		$key = 'akuko_rl_' . md5( $ip );

		$count = (int) get_transient( $key );

		if ( $count >= self::LIMIT ) {
			return new \WP_Error(
				'akuko_rate_limited',
				__( 'Too many requests. Please try again later.', 'akuko-mobile-api' ),
				array( 'status' => 429 )
			);
		}

		set_transient( $key, $count + 1, self::WINDOW );

		return true;
	}

	/**
	 * Get client IP.
	 */
	private function get_client_ip(): string {
		$headers = array( 'HTTP_CF_CONNECTING_IP', 'HTTP_X_FORWARDED_FOR', 'REMOTE_ADDR' );

		foreach ( $headers as $header ) {
			if ( ! empty( $_SERVER[ $header ] ) ) {
				$ip = sanitize_text_field( wp_unslash( $_SERVER[ $header ] ) );
				if ( str_contains( $ip, ',' ) ) {
					$ip = trim( explode( ',', $ip )[0] );
				}
				return $ip;
			}
		}

		return '0.0.0.0';
	}
}
