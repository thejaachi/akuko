<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Repositories\Interfaces\Payment_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\PaymentService_Interface;

defined( 'ABSPATH' ) || exit;

class PaymentService implements PaymentService_Interface {

	public function __construct(
		private Payment_Repository_Interface $payment_repository
	) {}

	public function verify( int $user_id, string $reference ): array|\WP_Error {
		return $this->payment_repository->verify_paystack( $reference );
	}

	public function get_history( int $user_id, int $limit, int $offset ): array {
		return $this->payment_repository->get_payment_history( $user_id, $limit, $offset );
	}
}
