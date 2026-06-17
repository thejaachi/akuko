<?php
namespace Akuko\MobileApi\Repositories\Interfaces;

defined( 'ABSPATH' ) || exit;

interface Reading_Repository_Interface {
	public function get_progress( int $user_id, int $book_id ): ?array;
	public function save_progress( int $user_id, int $book_id, array $data ): bool;
	public function get_bookmarks( int $user_id, ?int $book_id = null ): array;
	public function add_bookmark( int $user_id, int $book_id, array $data ): int;
	public function delete_bookmark( int $user_id, int $bookmark_id ): bool;
	public function get_highlights( int $user_id, ?int $book_id = null ): array;
	public function add_highlight( int $user_id, int $book_id, array $data ): int;
	public function delete_highlight( int $user_id, int $highlight_id ): bool;
	public function get_notes( int $user_id, ?int $book_id = null ): array;
	public function add_note( int $user_id, int $book_id, array $data ): int;
	public function delete_note( int $user_id, int $note_id ): bool;
	public function get_continue_reading( int $user_id, int $limit ): array;
	public function record_history( int $user_id, int $book_id ): void;
}
