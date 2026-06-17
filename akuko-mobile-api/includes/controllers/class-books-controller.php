<?php
namespace Akuko\MobileApi\Controllers;

use Akuko\MobileApi\Helpers\Pagination;
use Akuko\MobileApi\Middleware\Jwt_Auth_Middleware;
use Akuko\MobileApi\Middleware\Rate_Limit_Middleware;
use Akuko\MobileApi\Services\Interfaces\BookService_Interface;

defined( 'ABSPATH' ) || exit;

class Books_Controller extends Base_Controller {

	public function __construct(
		Jwt_Auth_Middleware $jwt,
		Rate_Limit_Middleware $rate_limit,
		private BookService_Interface $books
	) {
		parent::__construct( $jwt, $rate_limit );
	}

	public function index( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) {
			return $this->from_wp_error( $check );
		}

		$p = $this->pagination( $request );
		$result = $this->books->list_books( array(
			'limit'    => $p['per_page'],
			'offset'   => $p['offset'],
			'category' => sanitize_text_field( $request->get_param( 'category' ) ?? '' ),
		) );

		return $this->success( $result['items'], Pagination::meta( $p['page'], $p['per_page'], $result['total'] ) );
	}

	public function show( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) {
			return $this->from_wp_error( $check );
		}

		$book = $this->books->get_book( (int) $request['id'] );
		return $book ? $this->success( $book ) : $this->error( __( 'Book not found.', 'akuko-mobile-api' ), 'not_found', 404 );
	}

	public function featured( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) {
			return $this->from_wp_error( $check );
		}
		return $this->success( $this->books->get_featured( (int) ( $request->get_param( 'limit' ) ?? 10 ) ) );
	}

	public function trending( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) {
			return $this->from_wp_error( $check );
		}
		return $this->success( $this->books->get_trending( (int) ( $request->get_param( 'limit' ) ?? 10 ) ) );
	}

	public function new_releases( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) {
			return $this->from_wp_error( $check );
		}
		return $this->success( $this->books->get_new_releases( (int) ( $request->get_param( 'limit' ) ?? 10 ) ) );
	}

	public function related( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) {
			return $this->from_wp_error( $check );
		}
		return $this->success( $this->books->get_related( (int) $request['id'], (int) ( $request->get_param( 'limit' ) ?? 6 ) ) );
	}

	public function categories( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) {
			return $this->from_wp_error( $check );
		}
		return $this->success( $this->books->get_categories() );
	}
}
