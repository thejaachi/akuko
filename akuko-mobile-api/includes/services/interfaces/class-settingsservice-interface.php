<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface SettingsService_Interface {
    public function get_public_settings(): array;
}
