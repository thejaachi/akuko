<?php
namespace Akuko\MobileApi\Repositories\Interfaces;

defined( 'ABSPATH' ) || exit;

interface Wishlist_Repository_Interface {
	public function get_items( int $user_id ): array;
	public function add( int $user_id, int $book_id ): bool;
	public function remove( int $user_id, int $book_id ): bool;
	public function has( int $user_id, int $book_id ): bool;
}
