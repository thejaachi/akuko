<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface AuthenticationService_Interface {
    public function register(array $data): array|\WP_Error;
    public function login(string $email, string $password, ?string $device_id, ?string $device_name): array|\WP_Error;
    public function logout(int $user_id, ?string $refresh_token): bool;
    public function forgot_password(string $email): bool|\WP_Error;
    public function reset_password(string $token, string $password): bool|\WP_Error;
    public function refresh(string $refresh_token): array|\WP_Error;
    public function me(int $user_id): array;
    public function validate_access_token(string $token): object;
    public function oauth_google(string $token): array|\WP_Error;
    public function oauth_apple(string $token): array|\WP_Error;
    public function oauth_facebook(string $token): array|\WP_Error;
}
