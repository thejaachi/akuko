<?php
namespace Akuko\MobileApi\Repositories;

use Akuko\MobileApi\Repositories\Interfaces\Payment_Repository_Interface;

defined( 'ABSPATH' ) || exit;

class Payment_Repository implements Payment_Repository_Interface {

	public function verify_paystack( string $reference ): array|\WP_Error {
		$secret = $this->get_secret_key();
		if ( empty( $secret ) ) {
			return new \WP_Error( 'paystack_not_configured', __( 'Paystack secret key not configured.', 'akuko-mobile-api' ) );
		}

		$response = wp_remote_get(
			'https://api.paystack.co/transaction/verify/' . rawurlencode( $reference ),
			array(
				'headers' => array(
					'Authorization' => 'Bearer ' . $secret,
				),
				'timeout' => 30,
			)
		);

		if ( is_wp_error( $response ) ) {
			return $response;
		}

		$body = json_decode( wp_remote_retrieve_body( $response ), true );

		if ( empty( $body['status'] ) || empty( $body['data'] ) ) {
			return new \WP_Error( 'paystack_verify_failed', $body['message'] ?? __( 'Verification failed.', 'akuko-mobile-api' ) );
		}

		/**
		 * Allow existing Paystack WC plugin to augment verification.
		 */
		return apply_filters( 'akuko_mobile_api_paystack_verified', $body['data'], $reference );
	}

	public function get_payment_history( int $user_id, int $limit, int $offset ): array {
		$orders = wc_get_orders( array(
			'customer_id' => $user_id,
			'limit'       => $limit,
			'offset'      => $offset,
			'orderby'     => 'date',
			'order'       => 'DESC',
		) );

		$history = array();
		foreach ( $orders as $order ) {
			$history[] = array(
				'id'         => $order->get_id(),
				'total'      => $order->get_total(),
				'currency'   => $order->get_currency(),
				'status'     => $order->get_status(),
				'date'       => $order->get_date_created()?->format( 'c' ),
				'reference'  => $order->get_transaction_id(),
				'items_count'=> $order->get_item_count(),
			);
		}

		return $history;
	}

	public function get_secret_key(): string {
		if ( defined( 'AKUKO_PAYSTACK_SECRET_KEY' ) ) {
			return AKUKO_PAYSTACK_SECRET_KEY;
		}
		return (string) get_option( 'akuko_paystack_secret_key', '' );
	}
}
