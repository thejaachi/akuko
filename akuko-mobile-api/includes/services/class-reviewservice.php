<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Events\Event_Dispatcher;
use Akuko\MobileApi\Repositories\Interfaces\Review_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\ReviewService_Interface;

defined( 'ABSPATH' ) || exit;

class ReviewService implements ReviewService_Interface {

	public function __construct(
		private Review_Repository_Interface $review_repository,
		private Event_Dispatcher $events
	) {}

	public function list( int $book_id, int $limit, int $offset ): array {
		return array(
			'items' => $this->review_repository->get_for_product( $book_id, $limit, $offset ),
			'total' => $this->review_repository->count_for_product( $book_id ),
		);
	}

	public function create( int $book_id, int $user_id, array $data ): int|\WP_Error {
		$result = $this->review_repository->create( $book_id, $user_id, $data );
		if ( ! is_wp_error( $result ) ) {
			$this->events->dispatch( 'review_submitted', array( 'book_id' => $book_id, 'user_id' => $user_id ) );
		}
		return $result;
	}
}
