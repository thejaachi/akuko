<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Models\Book_Transformer;
use Akuko\MobileApi\Repositories\Interfaces\Book_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\BookService_Interface;
use Akuko\MobileApi\Services\Interfaces\RecommendationService_Interface;

defined( 'ABSPATH' ) || exit;

class RecommendationService implements RecommendationService_Interface {

	public function __construct(
		private BookService_Interface $book_service,
		private Book_Repository_Interface $book_repository
	) {}

	public function get_home( int $user_id ): array {
		return array(
			'featured'     => $this->book_service->get_featured( 10 ),
			'trending'     => $this->book_service->get_trending( 10 ),
			'new_releases' => $this->book_service->get_new_releases( 10 ),
			'for_you'      => $user_id > 0
				? Book_Transformer::collection( $this->book_repository->get_trending( 6 ) )
				: array(),
		);
	}
}
