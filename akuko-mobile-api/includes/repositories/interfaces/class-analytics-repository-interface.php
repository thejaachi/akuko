<?php
namespace Akuko\MobileApi\Repositories\Interfaces;

defined( 'ABSPATH' ) || exit;

interface Analytics_Repository_Interface {
	public function log_api_request( array $data ): void;
	public function log_event( int $user_id, string $event, array $payload ): void;
	public function get_api_logs( int $limit, int $offset ): array;
	public function count_api_logs(): int;
}
