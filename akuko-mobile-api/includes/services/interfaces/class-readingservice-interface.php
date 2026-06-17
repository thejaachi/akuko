<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface ReadingService_Interface {
    public function get_progress(int $user_id, int $book_id): ?array;
    public function save_progress(int $user_id, int $book_id, array $data): bool;
    public function get_bookmarks(int $user_id, ?int $book_id): array;
    public function add_bookmark(int $user_id, int $book_id, array $data): int;
    public function delete_bookmark(int $user_id, int $id): bool;
    public function get_highlights(int $user_id, ?int $book_id): array;
    public function add_highlight(int $user_id, int $book_id, array $data): int;
    public function delete_highlight(int $user_id, int $id): bool;
    public function get_notes(int $user_id, ?int $book_id): array;
    public function add_note(int $user_id, int $book_id, array $data): int;
    public function delete_note(int $user_id, int $id): bool;
}
