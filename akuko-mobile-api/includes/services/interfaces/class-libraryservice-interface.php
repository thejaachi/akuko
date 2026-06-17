<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface LibraryService_Interface {
    public function get_library(int $user_id, int $limit, int $offset): array;
    public function get_continue_reading(int $user_id, int $limit): array;
}
