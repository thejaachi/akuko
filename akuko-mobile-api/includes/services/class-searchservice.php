<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Models\Book_Transformer;
use Akuko\MobileApi\Repositories\Interfaces\Book_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\SearchService_Interface;

defined( 'ABSPATH' ) || exit;

class SearchService implements SearchService_Interface {

	public function __construct(
		private Book_Repository_Interface $book_repository
	) {}

	public function search( string $query, int $limit, int $offset ): array {
		$products = $this->book_repository->find_many( array(
			'search' => $query,
			'limit'  => $limit,
			'offset' => $offset,
		) );

		return array(
			'items' => Book_Transformer::collection( $products ),
			'total' => $this->book_repository->count( array( 'search' => $query ) ),
			'query' => $query,
		);
	}
}
