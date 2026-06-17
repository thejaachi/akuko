<?php
namespace Akuko\MobileApi\Repositories;

use Akuko\MobileApi\Repositories\Interfaces\Publisher_Repository_Interface;

defined( 'ABSPATH' ) || exit;

class Publisher_Repository implements Publisher_Repository_Interface {

	public function find( int $id ): ?array {
		$term = get_term( $id, 'product_tag' );
		if ( ! $term || is_wp_error( $term ) ) {
			return null;
		}
		return $this->transform( $term );
	}

	public function find_many( array $args ): array {
		$terms = get_terms( array(
			'taxonomy'   => 'product_tag',
			'hide_empty' => true,
			'number'     => (int) ( $args['limit'] ?? 20 ),
			'offset'     => (int) ( $args['offset'] ?? 0 ),
		) );

		if ( is_wp_error( $terms ) ) {
			return array();
		}

		return array_map( array( $this, 'transform' ), $terms );
	}

	private function transform( \WP_Term $term ): array {
		return array(
			'id'          => $term->term_id,
			'name'        => $term->name,
			'slug'        => $term->slug,
			'description' => $term->description,
			'count'       => $term->count,
		);
	}
}
