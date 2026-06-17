<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface PaymentService_Interface {
    public function verify(int $user_id, string $reference): array|\WP_Error;
    public function get_history(int $user_id, int $limit, int $offset): array;
}
