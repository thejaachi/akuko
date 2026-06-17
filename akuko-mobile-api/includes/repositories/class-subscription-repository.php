<?php
namespace Akuko\MobileApi\Repositories;

use Akuko\MobileApi\Repositories\Interfaces\Subscription_Repository_Interface;

defined( 'ABSPATH' ) || exit;

class Subscription_Repository implements Subscription_Repository_Interface {

	private function table(): string {
		global $wpdb;
		return $wpdb->prefix . 'akuko_subscriptions';
	}

	public function get_active( int $user_id ): ?array {
		global $wpdb;
		$row = $wpdb->get_row(
			$wpdb->prepare(
				"SELECT * FROM {$this->table()} WHERE user_id = %d AND status = 'active' AND (expires_at IS NULL OR expires_at > %s) ORDER BY id DESC LIMIT 1",
				$user_id,
				current_time( 'mysql', true )
			),
			ARRAY_A
		);
		return $row ?: null;
	}

	public function create( array $data ): int {
		global $wpdb;
		$wpdb->insert(
			$this->table(),
			array(
				'user_id'            => $data['user_id'],
				'plan'               => $data['plan'] ?? 'premium',
				'status'             => 'active',
				'paystack_reference' => $data['paystack_reference'] ?? null,
				'starts_at'          => $data['starts_at'] ?? current_time( 'mysql', true ),
				'expires_at'         => $data['expires_at'] ?? null,
			),
			array( '%d', '%s', '%s', '%s', '%s', '%s' )
		);
		return (int) $wpdb->insert_id;
	}

	public function deactivate( int $user_id ): bool {
		global $wpdb;
		return (bool) $wpdb->update(
			$this->table(),
			array( 'status' => 'cancelled' ),
			array( 'user_id' => $user_id, 'status' => 'active' ),
			array( '%s' ),
			array( '%d', '%s' )
		);
	}

	public function is_premium( int $user_id ): bool {
		return null !== $this->get_active( $user_id );
	}
}
