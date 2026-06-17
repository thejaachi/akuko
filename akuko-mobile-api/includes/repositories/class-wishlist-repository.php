<?php
namespace Akuko\MobileApi\Repositories;

use Akuko\MobileApi\Repositories\Interfaces\Wishlist_Repository_Interface;

defined( 'ABSPATH' ) || exit;

class Wishlist_Repository implements Wishlist_Repository_Interface {

	private function meta_key(): string {
		return '_akuko_wishlist';
	}

	public function get_items( int $user_id ): array {
		$items = get_user_meta( $user_id, $this->meta_key(), true );
		return is_array( $items ) ? array_map( 'intval', $items ) : array();
	}

	public function add( int $user_id, int $book_id ): bool {
		$items = $this->get_items( $user_id );
		if ( in_array( $book_id, $items, true ) ) {
			return true;
		}
		$items[] = $book_id;
		return update_user_meta( $user_id, $this->meta_key(), $items );
	}

	public function remove( int $user_id, int $book_id ): bool {
		$items = array_values( array_diff( $this->get_items( $user_id ), array( $book_id ) ) );
		return update_user_meta( $user_id, $this->meta_key(), $items );
	}

	public function has( int $user_id, int $book_id ): bool {
		return in_array( $book_id, $this->get_items( $user_id ), true );
	}
}
