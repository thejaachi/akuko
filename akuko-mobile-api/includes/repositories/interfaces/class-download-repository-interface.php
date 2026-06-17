<?php
namespace Akuko\MobileApi\Repositories\Interfaces;

defined( 'ABSPATH' ) || exit;

interface Download_Repository_Interface {
	public function create_token( array $data ): int;
	public function find_by_hash( string $hash ): ?array;
	public function mark_downloaded( int $id ): bool;
	public function get_user_downloads( int $user_id, int $limit, int $offset ): array;
}
