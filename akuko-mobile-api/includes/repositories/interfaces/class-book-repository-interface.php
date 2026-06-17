<?php
namespace Akuko\MobileApi\Repositories\Interfaces;

defined( 'ABSPATH' ) || exit;

interface Book_Repository_Interface {
	public function find( int $id ): ?\WC_Product;
	public function find_many( array $args ): array;
	public function count( array $args ): int;
	public function get_featured( int $limit ): array;
	public function get_trending( int $limit ): array;
	public function get_new_releases( int $limit ): array;
	public function get_related( int $book_id, int $limit ): array;
	public function get_categories(): array;
	public function user_owns_book( int $user_id, int $book_id ): bool;
}
