<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Services\Interfaces\NotificationService_Interface;

defined( 'ABSPATH' ) || exit;

class NotificationService implements NotificationService_Interface {

	public function list( int $user_id, int $limit, int $offset ): array {
		global $wpdb;
		$rows = $wpdb->get_results(
			$wpdb->prepare(
				"SELECT * FROM {$wpdb->prefix}akuko_notifications WHERE user_id = %d ORDER BY created_at DESC LIMIT %d OFFSET %d",
				$user_id,
				$limit,
				$offset
			),
			ARRAY_A
		) ?: array();

		$total = (int) $wpdb->get_var(
			$wpdb->prepare(
				"SELECT COUNT(*) FROM {$wpdb->prefix}akuko_notifications WHERE user_id = %d",
				$user_id
			)
		);

		return array( 'items' => $rows, 'total' => $total );
	}

	public function register_device( int $user_id, string $token, string $platform ): bool {
		$devices = get_user_meta( $user_id, '_akuko_push_devices', true );
		if ( ! is_array( $devices ) ) {
			$devices = array();
		}
		$devices[ md5( $token ) ] = array(
			'token'    => sanitize_text_field( $token ),
			'platform' => sanitize_text_field( $platform ),
			'updated'  => current_time( 'mysql', true ),
		);
		return (bool) update_user_meta( $user_id, '_akuko_push_devices', $devices );
	}
}
