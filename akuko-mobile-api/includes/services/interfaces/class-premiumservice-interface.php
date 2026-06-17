<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface PremiumService_Interface {
    public function get_status(int $user_id): array;
    public function subscribe(int $user_id, string $reference): array|\WP_Error;
    public function has_access(int $user_id, int $book_id): bool;
}
