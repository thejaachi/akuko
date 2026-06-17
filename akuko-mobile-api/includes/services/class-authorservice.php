<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Repositories\Interfaces\Author_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\AuthorService_Interface;

defined( 'ABSPATH' ) || exit;

class AuthorService implements AuthorService_Interface {

	public function __construct(
		private Author_Repository_Interface $author_repository
	) {}

	public function list( array $args ): array {
		return array(
			'items' => $this->author_repository->find_many( $args ),
			'total' => $this->author_repository->count( $args ),
		);
	}

	public function get( int $id ): ?array {
		return $this->author_repository->find( $id );
	}
}
