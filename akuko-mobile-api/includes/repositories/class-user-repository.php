<?php
namespace Akuko\MobileApi\Repositories;

use Akuko\MobileApi\Repositories\Interfaces\User_Repository_Interface;

defined( 'ABSPATH' ) || exit;

class User_Repository implements User_Repository_Interface {

	private function table(): string {
		global $wpdb;
		return $wpdb->prefix . 'akuko_refresh_tokens';
	}

	public function find( int $id ): ?\WP_User {
		$user = get_user_by( 'id', $id );
		return $user instanceof \WP_User ? $user : null;
	}

	public function find_by_email( string $email ): ?\WP_User {
		$user = get_user_by( 'email', sanitize_email( $email ) );
		return $user instanceof \WP_User ? $user : null;
	}

	public function create( array $data ): int|\WP_Error {
		$user_id = wp_create_user(
			$data['username'] ?? $data['email'],
			$data['password'],
			sanitize_email( $data['email'] )
		);

		if ( is_wp_error( $user_id ) ) {
			return $user_id;
		}

		if ( ! empty( $data['first_name'] ) ) {
			update_user_meta( $user_id, 'first_name', sanitize_text_field( $data['first_name'] ) );
		}
		if ( ! empty( $data['last_name'] ) ) {
			update_user_meta( $user_id, 'last_name', sanitize_text_field( $data['last_name'] ) );
		}

		return $user_id;
	}

	public function update( int $id, array $data ): bool|\WP_Error {
		$update = array( 'ID' => $id );
		if ( isset( $data['password'] ) ) {
			$update['user_pass'] = $data['password'];
		}
		$result = wp_update_user( $update );
		return is_wp_error( $result ) ? $result : true;
	}

	public function store_refresh_token( int $user_id, string $token_hash, string $expires_at, ?string $device_id, ?string $device_name ): int {
		global $wpdb;
		$wpdb->insert(
			$this->table(),
			array(
				'user_id'     => $user_id,
				'token_hash'  => $token_hash,
				'device_id'   => $device_id,
				'device_name' => $device_name,
				'expires_at'  => $expires_at,
			),
			array( '%d', '%s', '%s', '%s', '%s' )
		);
		return (int) $wpdb->insert_id;
	}

	public function find_refresh_token( string $token_hash ): ?array {
		global $wpdb;
		$row = $wpdb->get_row(
			$wpdb->prepare(
				"SELECT * FROM {$this->table()} WHERE token_hash = %s AND revoked_at IS NULL AND expires_at > %s",
				$token_hash,
				current_time( 'mysql', true )
			),
			ARRAY_A
		);
		return $row ?: null;
	}

	public function revoke_refresh_token( string $token_hash ): bool {
		global $wpdb;
		return (bool) $wpdb->update(
			$this->table(),
			array( 'revoked_at' => current_time( 'mysql', true ) ),
			array( 'token_hash' => $token_hash ),
			array( '%s' ),
			array( '%s' )
		);
	}

	public function revoke_all_tokens( int $user_id ): bool {
		global $wpdb;
		return (bool) $wpdb->update(
			$this->table(),
			array( 'revoked_at' => current_time( 'mysql', true ) ),
			array( 'user_id' => $user_id, 'revoked_at' => null ),
			array( '%s' ),
			array( '%d', '%s' )
		);
	}

	public function get_device_sessions( int $user_id ): array {
		global $wpdb;
		return $wpdb->get_results(
			$wpdb->prepare(
				"SELECT id, device_id, device_name, created_at, expires_at FROM {$this->table()} WHERE user_id = %d AND revoked_at IS NULL ORDER BY created_at DESC",
				$user_id
			),
			ARRAY_A
		) ?: array();
	}
}
