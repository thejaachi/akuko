<?php
namespace Akuko\MobileApi\Repositories;

use Akuko\MobileApi\Repositories\Interfaces\Book_Repository_Interface;

defined( 'ABSPATH' ) || exit;

class Book_Repository implements Book_Repository_Interface {

	public function find( int $id ): ?\WC_Product {
		$product = wc_get_product( $id );
		return ( $product && $product->is_visible() ) ? $product : null;
	}

	public function find_many( array $args ): array {
		$defaults = array(
			'status'  => 'publish',
			'limit'   => 20,
			'offset'  => 0,
			'orderby' => 'date',
			'order'   => 'DESC',
			'category'=> '',
			'search'  => '',
		);
		$args = wp_parse_args( $args, $defaults );

		$query_args = array(
			'status'  => $args['status'],
			'limit'   => $args['limit'],
			'offset'  => $args['offset'],
			'orderby' => $args['orderby'],
			'order'   => $args['order'],
			'type'    => array( 'simple', 'variable', 'downloadable' ),
		);

		if ( $args['category'] ) {
			$query_args['category'] = array( $args['category'] );
		}

		if ( $args['search'] ) {
			$query_args['s'] = $args['search'];
		}

		return wc_get_products( $query_args );
	}

	public function count( array $args ): int {
		$args['limit']  = -1;
		$args['return'] = 'ids';
		$query_args     = array_merge( $args, array( 'paginate' => true ) );
		$result         = wc_get_products( $query_args );
		return (int) ( $result->total ?? count( $this->find_many( $args ) ) );
	}

	public function get_featured( int $limit ): array {
		return wc_get_products( array(
			'status'   => 'publish',
			'limit'    => $limit,
			'featured' => true,
			'orderby'  => 'date',
			'order'    => 'DESC',
		) );
	}

	public function get_trending( int $limit ): array {
		return wc_get_products( array(
			'status'  => 'publish',
			'limit'   => $limit,
			'orderby' => 'popularity',
			'order'   => 'DESC',
		) );
	}

	public function get_new_releases( int $limit ): array {
		return wc_get_products( array(
			'status'  => 'publish',
			'limit'   => $limit,
			'orderby' => 'date',
			'order'   => 'DESC',
		) );
	}

	public function get_related( int $book_id, int $limit ): array {
		$product = $this->find( $book_id );
		if ( ! $product ) {
			return array();
		}
		$ids = wc_get_related_products( $book_id, $limit, $product->get_category_ids() );
		return array_filter( array_map( 'wc_get_product', $ids ) );
	}

	public function get_categories(): array {
		return get_terms( array(
			'taxonomy'   => 'product_cat',
			'hide_empty' => true,
		) );
	}

	public function user_owns_book( int $user_id, int $book_id ): bool {
		if ( $user_id <= 0 ) {
			return false;
		}

		$orders = wc_get_orders( array(
			'customer_id' => $user_id,
			'status'      => array( 'completed', 'processing' ),
			'limit'       => -1,
		) );

		foreach ( $orders as $order ) {
			foreach ( $order->get_items() as $item ) {
				if ( (int) $item->get_product_id() === $book_id ) {
					return true;
				}
			}
		}

		return false;
	}
}
