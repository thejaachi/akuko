<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface BookService_Interface {
    public function list_books(array $args): array;
    public function get_book(int $id): ?array;
    public function get_featured(int $limit): array;
    public function get_trending(int $limit): array;
    public function get_new_releases(int $limit): array;
    public function get_related(int $id, int $limit): array;
    public function get_categories(): array;
}
