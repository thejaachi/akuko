<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Models\Book_Transformer;
use Akuko\MobileApi\Repositories\Interfaces\Book_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\LibraryService_Interface;

defined( 'ABSPATH' ) || exit;

class LibraryService implements LibraryService_Interface {

	public function __construct(
		private Book_Repository_Interface $book_repository
	) {}

	public function get_library( int $user_id, int $limit, int $offset ): array {
		$orders = wc_get_orders( array(
			'customer_id' => $user_id,
			'status'      => array( 'completed', 'processing' ),
			'limit'       => -1,
		) );

		$book_ids = array();
		foreach ( $orders as $order ) {
			foreach ( $order->get_items() as $item ) {
				$book_ids[] = (int) $item->get_product_id();
			}
		}

		$book_ids = array_values( array_unique( $book_ids ) );
		$slice    = array_slice( $book_ids, $offset, $limit );
		$books    = array();

		foreach ( $slice as $id ) {
			$product = $this->book_repository->find( $id );
			if ( $product ) {
				$books[] = Book_Transformer::from_product( $product );
			}
		}

		return array( 'items' => $books, 'total' => count( $book_ids ) );
	}

	public function get_continue_reading( int $user_id, int $limit ): array {
		global $wpdb;
		$rows = $wpdb->get_results(
			$wpdb->prepare(
				"SELECT * FROM {$wpdb->prefix}akuko_reading_progress WHERE user_id = %d AND percentage < 100 ORDER BY updated_at DESC LIMIT %d",
				$user_id,
				$limit
			),
			ARRAY_A
		) ?: array();

		$items = array();
		foreach ( $rows as $row ) {
			$product = $this->book_repository->find( (int) $row['book_id'] );
			if ( $product ) {
				$book = Book_Transformer::from_product( $product );
				$book['progress'] = array(
					'position'   => $row['position'],
					'percentage' => (float) $row['percentage'],
					'chapter'    => $row['chapter'],
					'updated_at' => $row['updated_at'],
				);
				$items[] = $book;
			}
		}

		return $items;
	}
}
