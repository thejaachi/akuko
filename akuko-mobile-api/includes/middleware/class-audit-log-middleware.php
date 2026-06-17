<?php
/**
 * API audit logging middleware.
 *
 * @package Akuko\MobileApi
 */

namespace Akuko\MobileApi\Middleware;

use Akuko\MobileApi\Repositories\Interfaces\Analytics_Repository_Interface;

defined( 'ABSPATH' ) || exit;

/**
 * Logs API requests to api_logs table.
 */
final class Audit_Log_Middleware {

	public function __construct(
		private Analytics_Repository_Interface $analytics_repository
	) {}

	/**
	 * Log request after response.
	 *
	 * @param \WP_REST_Response|\WP_Error $response Response.
	 * @param \WP_REST_Server               $server   Server.
	 * @param \WP_REST_Request              $request  Request.
	 * @return \WP_REST_Response|\WP_Error
	 */
	public function log( $response, \WP_REST_Server $server, \WP_REST_Request $request ) {
		if ( ! str_starts_with( $request->get_route(), '/akuko/v1' ) ) {
			return $response;
		}

		$status = $response instanceof \WP_REST_Response ? $response->get_status() : 500;

		$this->analytics_repository->log_api_request(
			array(
				'user_id'     => get_current_user_id() ?: null,
				'endpoint'    => $request->get_route(),
				'method'      => $request->get_method(),
				'ip_address'  => $_SERVER['REMOTE_ADDR'] ?? null,
				'status_code' => $status,
				'request_body'=> wp_json_encode( $request->get_json_params() ),
			)
		);

		return $response;
	}
}
