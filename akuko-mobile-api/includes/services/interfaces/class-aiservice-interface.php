<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface AIService_Interface {
    public function summary(int $book_id, int $user_id): array|\WP_Error;
    public function chat(int $user_id, array $messages): array|\WP_Error;
}
