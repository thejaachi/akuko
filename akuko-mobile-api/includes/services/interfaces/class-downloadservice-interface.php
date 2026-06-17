<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface DownloadService_Interface {
    public function request_download(int $user_id, int $book_id, string $format): array|\WP_Error;
    public function validate_token(string $token): ?array;
}
