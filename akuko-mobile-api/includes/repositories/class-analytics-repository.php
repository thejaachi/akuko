<?php
namespace Akuko\MobileApi\Repositories;

use Akuko\MobileApi\Repositories\Interfaces\Analytics_Repository_Interface;

defined( 'ABSPATH' ) || exit;

class Analytics_Repository implements Analytics_Repository_Interface {

	private function logs_table(): string {
		global $wpdb;
		return $wpdb->prefix . 'akuko_api_logs';
	}

	public function log_api_request( array $data ): void {
		global $wpdb;
		$wpdb->insert(
			$this->logs_table(),
			array(
				'user_id'      => $data['user_id'],
				'endpoint'     => $data['endpoint'],
				'method'       => $data['method'],
				'ip_address'   => $data['ip_address'],
				'status_code'  => $data['status_code'],
				'request_body' => $data['request_body'],
			),
			array( '%d', '%s', '%s', '%s', '%d', '%s' )
		);
	}

	public function log_event( int $user_id, string $event, array $payload ): void {
		do_action( 'akuko_mobile_api_analytics_event', $user_id, $event, $payload );
	}

	public function get_api_logs( int $limit, int $offset ): array {
		global $wpdb;
		return $wpdb->get_results(
			$wpdb->prepare(
				"SELECT * FROM {$this->logs_table()} ORDER BY created_at DESC LIMIT %d OFFSET %d",
				$limit,
				$offset
			),
			ARRAY_A
		) ?: array();
	}

	public function count_api_logs(): int {
		global $wpdb;
		return (int) $wpdb->get_var( "SELECT COUNT(*) FROM {$this->logs_table()}" );
	}
}
