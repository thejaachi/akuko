<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface RecommendationService_Interface {
    public function get_home(int $user_id): array;
}
