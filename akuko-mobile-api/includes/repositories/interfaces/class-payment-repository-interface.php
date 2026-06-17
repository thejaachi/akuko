<?php
namespace Akuko\MobileApi\Repositories\Interfaces;

defined( 'ABSPATH' ) || exit;

interface Payment_Repository_Interface {
	public function verify_paystack( string $reference ): array|\WP_Error;
	public function get_payment_history( int $user_id, int $limit, int $offset ): array;
	public function get_secret_key(): string;
}
