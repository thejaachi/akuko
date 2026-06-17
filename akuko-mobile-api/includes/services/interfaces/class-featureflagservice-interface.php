<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface FeatureFlagService_Interface {
    public function get_all(): array;
    public function is_enabled(string $key, ?int $user_id = null): bool;
    public function update(string $key, bool $enabled): bool;
}
