<?php
namespace Akuko\MobileApi\Controllers;

use Akuko\MobileApi\Helpers\Pagination;
use Akuko\MobileApi\Helpers\Response;
use Akuko\MobileApi\Middleware\Jwt_Auth_Middleware;
use Akuko\MobileApi\Middleware\Rate_Limit_Middleware;

defined( 'ABSPATH' ) || exit;

abstract class Base_Controller {

	public function __construct(
		protected Jwt_Auth_Middleware $jwt,
		protected Rate_Limit_Middleware $rate_limit
	) {}

	protected function rate_limit_check( \WP_REST_Request $request ): bool|\WP_Error {
		return $this->rate_limit->check( $request );
	}

	protected function require_auth( \WP_REST_Request $request ): bool|\WP_Error {
		$rate = $this->rate_limit_check( $request );
		if ( is_wp_error( $rate ) ) {
			return $rate;
		}
		return $this->jwt->authenticate( $request );
	}

	protected function optional_auth( \WP_REST_Request $request ): bool|\WP_Error {
		$rate = $this->rate_limit_check( $request );
		if ( is_wp_error( $rate ) ) {
			return $rate;
		}
		$this->jwt->optional_authenticate( $request );
		return true;
	}

	protected function pagination( \WP_REST_Request $request ): array {
		return Pagination::from_request( $request );
	}

	protected function success( mixed $data = null, array $meta = array(), int $status = 200 ): \WP_REST_Response {
		return Response::success( $data, $meta, $status );
	}

	protected function error( string $message, string $code = 'error', int $status = 400 ): \WP_REST_Response {
		return Response::error( $message, $code, $status );
	}

	protected function from_wp_error( \WP_Error $error ): \WP_REST_Response {
		$status = $error->get_error_data()['status'] ?? 400;
		return Response::error( $error->get_error_message(), $error->get_error_code(), (int) $status );
	}
}
