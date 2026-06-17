<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Repositories\Interfaces\Analytics_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\AnalyticsService_Interface;

defined( 'ABSPATH' ) || exit;

class AnalyticsService implements AnalyticsService_Interface {

	public function __construct(
		private Analytics_Repository_Interface $analytics_repository
	) {}

	public function track_event( int $user_id, string $event, array $payload ): void {
		$this->analytics_repository->log_event( $user_id, sanitize_key( $event ), $payload );
	}
}
