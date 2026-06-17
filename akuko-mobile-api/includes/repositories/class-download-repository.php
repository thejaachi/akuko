<?php
namespace Akuko\MobileApi\Repositories;

use Akuko\MobileApi\Repositories\Interfaces\Download_Repository_Interface;

defined( 'ABSPATH' ) || exit;

class Download_Repository implements Download_Repository_Interface {

	private function table(): string {
		global $wpdb;
		return $wpdb->prefix . 'akuko_downloads';
	}

	public function create_token( array $data ): int {
		global $wpdb;
		$wpdb->insert(
			$this->table(),
			array(
				'user_id'    => $data['user_id'],
				'book_id'    => $data['book_id'],
				'format'     => $data['format'],
				'token_hash' => $data['token_hash'],
				'expires_at' => $data['expires_at'],
			),
			array( '%d', '%d', '%s', '%s', '%s' )
		);
		return (int) $wpdb->insert_id;
	}

	public function find_by_hash( string $hash ): ?array {
		global $wpdb;
		$row = $wpdb->get_row(
			$wpdb->prepare(
				"SELECT * FROM {$this->table()} WHERE token_hash = %s AND expires_at > %s",
				$hash,
				current_time( 'mysql', true )
			),
			ARRAY_A
		);
		return $row ?: null;
	}

	public function mark_downloaded( int $id ): bool {
		global $wpdb;
		return (bool) $wpdb->update(
			$this->table(),
			array( 'downloaded_at' => current_time( 'mysql', true ) ),
			array( 'id' => $id ),
			array( '%s' ),
			array( '%d' )
		);
	}

	public function get_user_downloads( int $user_id, int $limit, int $offset ): array {
		global $wpdb;
		return $wpdb->get_results(
			$wpdb->prepare(
				"SELECT * FROM {$this->table()} WHERE user_id = %d ORDER BY created_at DESC LIMIT %d OFFSET %d",
				$user_id,
				$limit,
				$offset
			),
			ARRAY_A
		) ?: array();
	}
}
