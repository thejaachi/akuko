<?php
namespace Akuko\MobileApi\Repositories\Interfaces;

defined( 'ABSPATH' ) || exit;

interface Subscription_Repository_Interface {
	public function get_active( int $user_id ): ?array;
	public function create( array $data ): int;
	public function deactivate( int $user_id ): bool;
	public function is_premium( int $user_id ): bool;
}
