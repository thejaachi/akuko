<?php
namespace Akuko\MobileApi\Services\Interfaces;

defined( 'ABSPATH' ) || exit;

interface PublisherService_Interface {
    public function list(array $args): array;
}
