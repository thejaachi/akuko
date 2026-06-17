<?php
namespace Akuko\MobileApi\Repositories\Interfaces;

defined( 'ABSPATH' ) || exit;

interface Review_Repository_Interface {
	public function get_for_product( int $product_id, int $limit, int $offset ): array;
	public function count_for_product( int $product_id ): int;
	public function create( int $product_id, int $user_id, array $data ): int|\WP_Error;
}
