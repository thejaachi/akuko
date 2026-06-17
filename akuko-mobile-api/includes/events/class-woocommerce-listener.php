<?php
namespace Akuko\MobileApi\Events;

use Akuko\MobileApi\Repositories\Interfaces\Book_Repository_Interface;

defined( 'ABSPATH' ) || exit;

class WooCommerce_Listener {

	public function __construct(
		private Event_Dispatcher $events,
		private Book_Repository_Interface $book_repository
	) {}

	public function register(): void {
		add_action( 'woocommerce_order_status_completed', array( $this, 'on_order_completed' ), 10, 1 );
	}

	public function on_order_completed( int $order_id ): void {
		$order = wc_get_order( $order_id );
		if ( ! $order ) {
			return;
		}

		$user_id = $order->get_customer_id();
		foreach ( $order->get_items() as $item ) {
			$book_id = (int) $item->get_product_id();
			$this->events->dispatch( 'book_purchased', array(
				'user_id'  => $user_id,
				'book_id'  => $book_id,
				'order_id' => $order_id,
			) );
		}
	}
}
