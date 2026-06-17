<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Repositories\Interfaces\Publisher_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\PublisherService_Interface;

defined( 'ABSPATH' ) || exit;

class PublisherService implements PublisherService_Interface {

	public function __construct(
		private Publisher_Repository_Interface $publisher_repository
	) {}

	public function list( array $args ): array {
		return array( 'items' => $this->publisher_repository->find_many( $args ) );
	}
}
