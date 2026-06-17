<?php
namespace Akuko\MobileApi\Repositories\Interfaces;

defined( 'ABSPATH' ) || exit;

interface Publisher_Repository_Interface {
	public function find( int $id ): ?array;
	public function find_many( array $args ): array;
}
