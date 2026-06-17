<?php
/**
 * Consistent JSON API response envelope.
 *
 * @package Akuko\MobileApi
 */

namespace Akuko\MobileApi\Helpers;

defined( 'ABSPATH' ) || exit;

/**
 * API response helper.
 */
final class Response {

	/**
	 * Success response.
	 *
	 * @param mixed                $data   Response data.
	 * @param array<string, mixed> $meta   Meta information.
	 * @param int                  $status HTTP status.
	 * @return \WP_REST_Response
	 */
	public static function success( mixed $data = null, array $meta = array(), int $status = 200 ): \WP_REST_Response {
		return new \WP_REST_Response(
			array(
				'success' => true,
				'data'    => $data,
				'error'   => null,
				'meta'    => $meta,
			),
			$status
		);
	}

	/**
	 * Error response.
	 *
	 * @param string               $message Error message.
	 * @param string               $code    Error code.
	 * @param int                  $status  HTTP status.
	 * @param array<string, mixed> $meta    Meta information.
	 * @return \WP_REST_Response
	 */
	public static function error( string $message, string $code = 'error', int $status = 400, array $meta = array() ): \WP_REST_Response {
		return new \WP_REST_Response(
			array(
				'success' => false,
				'data'    => null,
				'error'   => array(
					'code'    => $code,
					'message' => $message,
				),
				'meta'    => $meta,
			),
			$status
		);
	}

	/**
	 * Not implemented stub.
	 *
	 * @param string $feature Feature name.
	 * @return \WP_REST_Response
	 */
	public static function not_implemented( string $feature ): \WP_REST_Response {
		return self::error(
			sprintf( '%s is not yet implemented.', $feature ),
			'not_implemented',
			501
		);
	}
}
