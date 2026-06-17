<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface AudiobookService_Interface {
    public function get_for_book(int $book_id, int $user_id): array|\WP_Error;
}
