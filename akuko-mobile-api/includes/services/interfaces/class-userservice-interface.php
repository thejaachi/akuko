<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface UserService_Interface {
    public function get_profile(int $user_id): array;
}
