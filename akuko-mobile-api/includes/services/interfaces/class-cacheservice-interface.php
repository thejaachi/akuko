<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface CacheService_Interface {
    public function get(string $key): mixed;
    public function set(string $key, mixed $value, int $ttl = 3600): bool;
    public function delete(string $key): bool;
    public function flush_prefix(string $prefix): void;
}
