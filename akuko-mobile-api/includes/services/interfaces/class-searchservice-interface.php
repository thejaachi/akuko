<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface SearchService_Interface {
    public function search(string $query, int $limit, int $offset): array;
}
