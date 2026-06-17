<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Repositories\Interfaces\Reading_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\ReadingService_Interface;

defined( 'ABSPATH' ) || exit;

class ReadingService implements ReadingService_Interface {

	public function __construct(
		private Reading_Repository_Interface $reading_repository
	) {}

	public function get_progress( int $user_id, int $book_id ): ?array {
		return $this->reading_repository->get_progress( $user_id, $book_id );
	}

	public function save_progress( int $user_id, int $book_id, array $data ): bool {
		$this->reading_repository->record_history( $user_id, $book_id );
		return $this->reading_repository->save_progress( $user_id, $book_id, $data );
	}

	public function get_bookmarks( int $user_id, ?int $book_id = null ): array {
		return $this->reading_repository->get_bookmarks( $user_id, $book_id );
	}

	public function add_bookmark( int $user_id, int $book_id, array $data ): int {
		return $this->reading_repository->add_bookmark( $user_id, $book_id, $data );
	}

	public function delete_bookmark( int $user_id, int $id ): bool {
		return $this->reading_repository->delete_bookmark( $user_id, $id );
	}

	public function get_highlights( int $user_id, ?int $book_id = null ): array {
		return $this->reading_repository->get_highlights( $user_id, $book_id );
	}

	public function add_highlight( int $user_id, int $book_id, array $data ): int {
		return $this->reading_repository->add_highlight( $user_id, $book_id, $data );
	}

	public function delete_highlight( int $user_id, int $id ): bool {
		return $this->reading_repository->delete_highlight( $user_id, $id );
	}

	public function get_notes( int $user_id, ?int $book_id = null ): array {
		return $this->reading_repository->get_notes( $user_id, $book_id );
	}

	public function add_note( int $user_id, int $book_id, array $data ): int {
		return $this->reading_repository->add_note( $user_id, $book_id, $data );
	}

	public function delete_note( int $user_id, int $id ): bool {
		return $this->reading_repository->delete_note( $user_id, $id );
	}
}
