<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface NotificationService_Interface {
    public function list(int $user_id, int $limit, int $offset): array;
    public function register_device(int $user_id, string $token, string $platform): bool;
}
