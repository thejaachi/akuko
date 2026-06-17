<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface AuthorService_Interface {
    public function list(array $args): array;
    public function get(int $id): ?array;
}
