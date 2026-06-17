<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Events\Event_Dispatcher;
use Akuko\MobileApi\Repositories\Interfaces\Book_Repository_Interface;
use Akuko\MobileApi\Repositories\Interfaces\Payment_Repository_Interface;
use Akuko\MobileApi\Repositories\Interfaces\Subscription_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\PremiumService_Interface;

defined( 'ABSPATH' ) || exit;

class PremiumService implements PremiumService_Interface {

	public function __construct(
		private Subscription_Repository_Interface $subscription_repository,
		private Payment_Repository_Interface $payment_repository,
		private Book_Repository_Interface $book_repository,
		private Event_Dispatcher $events
	) {}

	public function get_status( int $user_id ): array {
		$sub = $this->subscription_repository->get_active( $user_id );

		return array(
			'is_premium' => null !== $sub,
			'plan'       => $sub['plan'] ?? null,
			'starts_at'  => $sub['starts_at'] ?? null,
			'expires_at' => $sub['expires_at'] ?? null,
			'benefits'   => array(
				'no_ads'              => null !== $sub,
				'unlimited_downloads' => null !== $sub,
				'ai_features'         => null !== $sub,
				'audiobooks'          => null !== $sub,
				'premium_themes'      => null !== $sub,
				'offline_reading'     => null !== $sub,
				'cross_device_sync'   => null !== $sub,
			),
		);
	}

	public function subscribe( int $user_id, string $reference ): array|\WP_Error {
		$verified = $this->payment_repository->verify_paystack( $reference );
		if ( is_wp_error( $verified ) ) {
			return $verified;
		}

		if ( ( $verified['status'] ?? '' ) !== 'success' ) {
			return new \WP_Error( 'payment_failed', __( 'Payment was not successful.', 'akuko-mobile-api' ) );
		}

		$expires = gmdate( 'Y-m-d H:i:s', strtotime( '+1 year' ) );

		$this->subscription_repository->create( array(
			'user_id'            => $user_id,
			'paystack_reference' => $reference,
			'expires_at'         => $expires,
		) );

		$this->events->dispatch( 'premium_activated', array( 'user_id' => $user_id, 'reference' => $reference ) );

		return $this->get_status( $user_id );
	}

	public function has_access( int $user_id, int $book_id ): bool {
		if ( $this->subscription_repository->is_premium( $user_id ) ) {
			return true;
		}
		return $this->book_repository->user_owns_book( $user_id, $book_id );
	}
}
