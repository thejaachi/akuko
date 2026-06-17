<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Events\Event_Dispatcher;
use Akuko\MobileApi\Repositories\Interfaces\Download_Repository_Interface;
use Akuko\MobileApi\Repositories\Interfaces\Payment_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\DownloadService_Interface;
use Akuko\MobileApi\Services\Interfaces\PremiumService_Interface;

defined( 'ABSPATH' ) || exit;

class DownloadService implements DownloadService_Interface {

	private const TOKEN_TTL = 900;

	public function __construct(
		private Download_Repository_Interface $download_repository,
		private PremiumService_Interface $premium_service,
		private Payment_Repository_Interface $payment_repository,
		private Event_Dispatcher $events
	) {}

	public function request_download( int $user_id, int $book_id, string $format ): array|\WP_Error {
		if ( ! $this->premium_service->has_access( $user_id, $book_id ) ) {
			return new \WP_Error( 'access_denied', __( 'Purchase or premium subscription required.', 'akuko-mobile-api' ), array( 'status' => 403 ) );
		}

		$token      = bin2hex( random_bytes( 32 ) );
		$hash       = hash_hmac( 'sha256', $token, $this->get_signing_key() );
		$expires_at = gmdate( 'Y-m-d H:i:s', time() + self::TOKEN_TTL );

		$this->download_repository->create_token( array(
			'user_id'    => $user_id,
			'book_id'    => $book_id,
			'format'     => sanitize_text_field( $format ),
			'token_hash' => $hash,
			'expires_at' => $expires_at,
		) );

		$url = add_query_arg(
			array(
				'akuko_download' => $token,
				'book'           => $book_id,
				'format'         => $format,
			),
			rest_url( 'akuko/v1/downloads/serve' )
		);

		$this->events->dispatch( 'book_downloaded', array( 'user_id' => $user_id, 'book_id' => $book_id ) );

		return array(
			'url'        => $url,
			'expires_at' => $expires_at,
			'expires_in' => self::TOKEN_TTL,
		);
	}

	public function validate_token( string $token ): ?array {
		$hash = hash_hmac( 'sha256', $token, $this->get_signing_key() );
		return $this->download_repository->find_by_hash( $hash );
	}

	private function get_signing_key(): string {
		if ( defined( 'AKUKO_DOWNLOAD_SIGNING_KEY' ) ) {
			return AKUKO_DOWNLOAD_SIGNING_KEY;
		}
		$key = get_option( 'akuko_download_signing_key' );
		if ( ! $key ) {
			$key = wp_generate_password( 64, true, true );
			update_option( 'akuko_download_signing_key', $key, false );
		}
		return $key;
	}
}
