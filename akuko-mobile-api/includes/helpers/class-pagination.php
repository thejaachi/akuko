<?php
/**
 * Pagination helper.
 *
 * @package Akuko\MobileApi
 */

namespace Akuko\MobileApi\Helpers;

defined( 'ABSPATH' ) || exit;

/**
 * Pagination utilities.
 */
final class Pagination {

	/**
	 * Parse pagination from request.
	 *
	 * @param \WP_REST_Request $request Request object.
	 * @return array{page: int, per_page: int, offset: int}
	 */
	public static function from_request( \WP_REST_Request $request ): array {
		$page     = max( 1, (int) $request->get_param( 'page' ) ?: 1 );
		$per_page = (int) $request->get_param( 'per_page' ) ?: 20;
		$per_page = min( 100, max( 1, $per_page ) );

		return array(
			'page'     => $page,
			'per_page' => $per_page,
			'offset'   => ( $page - 1 ) * $per_page,
		);
	}

	/**
	 * Build meta array.
	 *
	 * @param int $page       Current page.
	 * @param int $per_page   Items per page.
	 * @param int $total      Total items.
	 * @return array<string, int>
	 */
	public static function meta( int $page, int $per_page, int $total ): array {
		return array(
			'page'        => $page,
			'per_page'    => $per_page,
			'total'       => $total,
			'total_pages' => (int) ceil( $total / max( 1, $per_page ) ),
		);
	}
}
