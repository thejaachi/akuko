<?php
namespace Akuko\MobileApi\Repositories\Interfaces;

defined( 'ABSPATH' ) || exit;

interface User_Repository_Interface {
	public function find( int $id ): ?\WP_User;
	public function find_by_email( string $email ): ?\WP_User;
	public function create( array $data ): int|\WP_Error;
	public function update( int $id, array $data ): bool|\WP_Error;
	public function store_refresh_token( int $user_id, string $token_hash, string $expires_at, ?string $device_id, ?string $device_name ): int;
	public function find_refresh_token( string $token_hash ): ?array;
	public function revoke_refresh_token( string $token_hash ): bool;
	public function revoke_all_tokens( int $user_id ): bool;
	public function get_device_sessions( int $user_id ): array;
}
