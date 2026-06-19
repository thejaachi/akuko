<?php
namespace Akuko\MobileApi\Helpers;

use Akuko\MobileApi\Helpers\Interfaces\Google_Token_Verifier_Interface;
use Firebase\JWT\JWK;
use Firebase\JWT\JWT;

defined( 'ABSPATH' ) || exit;

class Google_Token_Verifier implements Google_Token_Verifier_Interface {

	private const JWKS_URL     = 'https://www.googleapis.com/oauth2/v3/certs';
	private const CACHE_KEY    = 'akuko_google_jwks';
	private const CACHE_TTL    = 3600;
	private const VALID_ISSUERS = array( 'accounts.google.com', 'https://accounts.google.com' );

	public function verify( string $id_token ): array|\WP_Error {
		$id_token = trim( $id_token );
		if ( '' === $id_token ) {
			return new \WP_Error( 'invalid_token', __( 'Google ID token is required.', 'akuko-mobile-api' ), array( 'status' => 400 ) );
		}

		$client_ids = Auth_Config::google_client_ids();
		if ( empty( $client_ids ) ) {
			return new \WP_Error(
				'google_not_configured',
				__( 'Google sign-in is not configured on the server.', 'akuko-mobile-api' ),
				array( 'status' => 503 )
			);
		}

		$jwks = $this->get_jwks();
		if ( is_wp_error( $jwks ) ) {
			return $jwks;
		}

		try {
			$keys    = JWK::parseKeySet( $jwks );
			$payload = JWT::decode( $id_token, $keys );
		} catch ( \Throwable $e ) {
			return new \WP_Error(
				'invalid_token',
				__( 'Invalid Google ID token.', 'akuko-mobile-api' ),
				array( 'status' => 401 )
			);
		}

		$claims = (array) $payload;

		if ( empty( $claims['iss'] ) || ! in_array( (string) $claims['iss'], self::VALID_ISSUERS, true ) ) {
			return new \WP_Error( 'invalid_token', __( 'Invalid Google token issuer.', 'akuko-mobile-api' ), array( 'status' => 401 ) );
		}

		$aud = (string) ( $claims['aud'] ?? '' );
		if ( '' === $aud || ! in_array( $aud, $client_ids, true ) ) {
			return new \WP_Error( 'invalid_token', __( 'Google token audience mismatch.', 'akuko-mobile-api' ), array( 'status' => 401 ) );
		}

		if ( ! empty( $claims['exp'] ) && (int) $claims['exp'] < time() ) {
			return new \WP_Error( 'invalid_token', __( 'Google ID token has expired.', 'akuko-mobile-api' ), array( 'status' => 401 ) );
		}

		if ( isset( $claims['email_verified'] ) && ! $claims['email_verified'] ) {
			return new \WP_Error( 'invalid_token', __( 'Google email is not verified.', 'akuko-mobile-api' ), array( 'status' => 401 ) );
		}

		$email = sanitize_email( (string) ( $claims['email'] ?? '' ) );
		if ( '' === $email || ! is_email( $email ) ) {
			return new \WP_Error( 'invalid_token', __( 'Google account email is missing.', 'akuko-mobile-api' ), array( 'status' => 401 ) );
		}

		$sub = (string) ( $claims['sub'] ?? '' );
		if ( '' === $sub ) {
			return new \WP_Error( 'invalid_token', __( 'Google account subject is missing.', 'akuko-mobile-api' ), array( 'status' => 401 ) );
		}

		return array(
			'email'       => $email,
			'given_name'  => isset( $claims['given_name'] ) ? sanitize_text_field( (string) $claims['given_name'] ) : '',
			'family_name' => isset( $claims['family_name'] ) ? sanitize_text_field( (string) $claims['family_name'] ) : '',
			'name'        => isset( $claims['name'] ) ? sanitize_text_field( (string) $claims['name'] ) : '',
			'sub'         => $sub,
		);
	}

	/**
	 * @return array<string,mixed>|\WP_Error
	 */
	private function get_jwks(): array|\WP_Error {
		$cached = get_transient( self::CACHE_KEY );
		if ( is_array( $cached ) && ! empty( $cached['keys'] ) ) {
			return $cached;
		}

		$response = wp_remote_get(
			self::JWKS_URL,
			array(
				'timeout' => 10,
			)
		);

		if ( is_wp_error( $response ) ) {
			return new \WP_Error(
				'google_jwks_unavailable',
				__( 'Unable to verify Google sign-in right now.', 'akuko-mobile-api' ),
				array( 'status' => 503 )
			);
		}

		$code = (int) wp_remote_retrieve_response_code( $response );
		$body = wp_remote_retrieve_body( $response );
		$jwks = json_decode( $body, true );

		if ( 200 !== $code || ! is_array( $jwks ) || empty( $jwks['keys'] ) ) {
			return new \WP_Error(
				'google_jwks_unavailable',
				__( 'Unable to verify Google sign-in right now.', 'akuko-mobile-api' ),
				array( 'status' => 503 )
			);
		}

		set_transient( self::CACHE_KEY, $jwks, self::CACHE_TTL );

		return $jwks;
	}
}
