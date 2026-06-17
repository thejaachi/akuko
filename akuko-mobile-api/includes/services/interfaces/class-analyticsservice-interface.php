<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface AnalyticsService_Interface {
    public function track_event(int $user_id, string $event, array $payload): void;
}
