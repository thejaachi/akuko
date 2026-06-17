<?php
namespace Akuko\MobileApi\Repositories;

use Akuko\MobileApi\Repositories\Interfaces\Reading_Repository_Interface;

defined( 'ABSPATH' ) || exit;

class Reading_Repository implements Reading_Repository_Interface {

	private function prefix(): string {
		global $wpdb;
		return $wpdb->prefix . 'akuko_';
	}

	public function get_progress( int $user_id, int $book_id ): ?array {
		global $wpdb;
		$row = $wpdb->get_row(
			$wpdb->prepare(
				"SELECT * FROM {$this->prefix()}reading_progress WHERE user_id = %d AND book_id = %d",
				$user_id,
				$book_id
			),
			ARRAY_A
		);
		return $row ?: null;
	}

	public function save_progress( int $user_id, int $book_id, array $data ): bool {
		global $wpdb;
		$table = $this->prefix() . 'reading_progress';
		$existing = $this->get_progress( $user_id, $book_id );

		$row = array(
			'position'    => sanitize_text_field( $data['position'] ?? '0' ),
			'percentage'  => (float) ( $data['percentage'] ?? 0 ),
			'chapter'     => sanitize_text_field( $data['chapter'] ?? '' ),
			'updated_at'  => current_time( 'mysql', true ),
		);

		if ( $existing ) {
			return (bool) $wpdb->update( $table, $row, array( 'id' => $existing['id'] ), array( '%s', '%f', '%s', '%s' ), array( '%d' ) );
		}

		$row['user_id'] = $user_id;
		$row['book_id'] = $book_id;
		return (bool) $wpdb->insert( $table, $row, array( '%d', '%d', '%s', '%f', '%s', '%s' ) );
	}

	public function get_bookmarks( int $user_id, ?int $book_id = null ): array {
		global $wpdb;
		$sql = "SELECT * FROM {$this->prefix()}bookmarks WHERE user_id = %d";
		$params = array( $user_id );
		if ( $book_id ) {
			$sql .= ' AND book_id = %d';
			$params[] = $book_id;
		}
		$sql .= ' ORDER BY created_at DESC';
		return $wpdb->get_results( $wpdb->prepare( $sql, ...$params ), ARRAY_A ) ?: array();
	}

	public function add_bookmark( int $user_id, int $book_id, array $data ): int {
		global $wpdb;
		$wpdb->insert(
			$this->prefix() . 'bookmarks',
			array(
				'user_id' => $user_id,
				'book_id' => $book_id,
				'cfi'     => sanitize_text_field( $data['cfi'] ?? '' ),
				'label'   => sanitize_text_field( $data['label'] ?? '' ),
			),
			array( '%d', '%d', '%s', '%s' )
		);
		return (int) $wpdb->insert_id;
	}

	public function delete_bookmark( int $user_id, int $bookmark_id ): bool {
		global $wpdb;
		return (bool) $wpdb->delete(
			$this->prefix() . 'bookmarks',
			array( 'id' => $bookmark_id, 'user_id' => $user_id ),
			array( '%d', '%d' )
		);
	}

	public function get_highlights( int $user_id, ?int $book_id = null ): array {
		global $wpdb;
		$sql = "SELECT * FROM {$this->prefix()}book_highlights WHERE user_id = %d";
		$params = array( $user_id );
		if ( $book_id ) {
			$sql .= ' AND book_id = %d';
			$params[] = $book_id;
		}
		return $wpdb->get_results( $wpdb->prepare( $sql . ' ORDER BY created_at DESC', ...$params ), ARRAY_A ) ?: array();
	}

	public function add_highlight( int $user_id, int $book_id, array $data ): int {
		global $wpdb;
		$wpdb->insert(
			$this->prefix() . 'book_highlights',
			array(
				'user_id' => $user_id,
				'book_id' => $book_id,
				'text'    => sanitize_textarea_field( $data['text'] ?? '' ),
				'cfi'     => sanitize_text_field( $data['cfi'] ?? '' ),
				'color'   => sanitize_hex_color( $data['color'] ?? '#FFEB3B' ),
			),
			array( '%d', '%d', '%s', '%s', '%s' )
		);
		return (int) $wpdb->insert_id;
	}

	public function delete_highlight( int $user_id, int $highlight_id ): bool {
		global $wpdb;
		return (bool) $wpdb->delete(
			$this->prefix() . 'book_highlights',
			array( 'id' => $highlight_id, 'user_id' => $user_id ),
			array( '%d', '%d' )
		);
	}

	public function get_notes( int $user_id, ?int $book_id = null ): array {
		global $wpdb;
		$sql = "SELECT * FROM {$this->prefix()}book_notes WHERE user_id = %d";
		$params = array( $user_id );
		if ( $book_id ) {
			$sql .= ' AND book_id = %d';
			$params[] = $book_id;
		}
		return $wpdb->get_results( $wpdb->prepare( $sql . ' ORDER BY updated_at DESC', ...$params ), ARRAY_A ) ?: array();
	}

	public function add_note( int $user_id, int $book_id, array $data ): int {
		global $wpdb;
		$wpdb->insert(
			$this->prefix() . 'book_notes',
			array(
				'user_id' => $user_id,
				'book_id' => $book_id,
				'content' => sanitize_textarea_field( $data['content'] ?? '' ),
				'cfi'     => sanitize_text_field( $data['cfi'] ?? '' ),
			),
			array( '%d', '%d', '%s', '%s' )
		);
		return (int) $wpdb->insert_id;
	}

	public function delete_note( int $user_id, int $note_id ): bool {
		global $wpdb;
		return (bool) $wpdb->delete(
			$this->prefix() . 'book_notes',
			array( 'id' => $note_id, 'user_id' => $user_id ),
			array( '%d', '%d' )
		);
	}

	public function get_continue_reading( int $user_id, int $limit ): array {
		global $wpdb;
		return $wpdb->get_results(
			$wpdb->prepare(
				"SELECT * FROM {$this->prefix()}reading_progress WHERE user_id = %d AND percentage < 100 ORDER BY updated_at DESC LIMIT %d",
				$user_id,
				$limit
			),
			ARRAY_A
		) ?: array();
	}

	public function record_history( int $user_id, int $book_id ): void {
		global $wpdb;
		$wpdb->insert(
			$this->prefix() . 'reading_history',
			array( 'user_id' => $user_id, 'book_id' => $book_id ),
			array( '%d', '%d' )
		);
	}
}
