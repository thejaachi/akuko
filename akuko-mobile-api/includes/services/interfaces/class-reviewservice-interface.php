<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface ReviewService_Interface {
    public function list(int $book_id, int $limit, int $offset): array;
    public function create(int $book_id, int $user_id, array $data): int|\WP_Error;
}
