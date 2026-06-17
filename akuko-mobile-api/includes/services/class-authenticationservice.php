<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Models\User_Transformer;
use Akuko\MobileApi\Repositories\Interfaces\User_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\AuthenticationService_Interface;
use Firebase\JWT\JWT;
use Firebase\JWT\Key;

defined( 'ABSPATH' ) || exit;

class AuthenticationService implements AuthenticationService_Interface {

	private const ACCESS_TTL  = 3600;
	private const REFRESH_TTL = 2592000;

	public function __construct(
		private User_Repository_Interface $user_repository
	) {}

	public function register( array $data ): array|\WP_Error {
		if ( empty( $data['email'] ) || empty( $data['password'] ) ) {
			return new \WP_Error( 'invalid_data', __( 'Email and password are required.', 'akuko-mobile-api' ) );
		}

		if ( email_exists( $data['email'] ) ) {
			return new \WP_Error( 'email_exists', __( 'Email already registered.', 'akuko-mobile-api' ), array( 'status' => 409 ) );
		}

		$user_id = $this->user_repository->create( $data );
		if ( is_wp_error( $user_id ) ) {
			return $user_id;
		}

		return $this->issue_tokens( $user_id, $data['device_id'] ?? null, $data['device_name'] ?? null );
	}

	public function login( string $email, string $password, ?string $device_id, ?string $device_name ): array|\WP_Error {
		$user = wp_authenticate( $email, $password );
		if ( is_wp_error( $user ) ) {
			return new \WP_Error( 'invalid_credentials', __( 'Invalid email or password.', 'akuko-mobile-api' ), array( 'status' => 401 ) );
		}

		return $this->issue_tokens( $user->ID, $device_id, $device_name );
	}

	public function logout( int $user_id, ?string $refresh_token ): bool {
		if ( $refresh_token ) {
			$this->user_repository->revoke_refresh_token( hash( 'sha256', $refresh_token ) );
		} else {
			$this->user_repository->revoke_all_tokens( $user_id );
		}
		return true;
	}

	public function forgot_password( string $email ): bool|\WP_Error {
		$user = $this->user_repository->find_by_email( $email );
		if ( ! $user ) {
			return true;
		}

		$key = get_password_reset_key( $user );
		if ( is_wp_error( $key ) ) {
			return $key;
		}

		do_action( 'akuko_mobile_api_password_reset_requested', $user, $key );
		return true;
	}

	public function reset_password( string $token, string $password ): bool|\WP_Error {
		$user = check_password_reset_key( $token, '' );
		if ( is_wp_error( $user ) ) {
			return $user;
		}

		reset_password( $user, $password );
		$this->user_repository->revoke_all_tokens( $user->ID );
		return true;
	}

	public function refresh( string $refresh_token ): array|\WP_Error {
		$hash = hash( 'sha256', $refresh_token );
		$row  = $this->user_repository->find_refresh_token( $hash );

		if ( ! $row ) {
			return new \WP_Error( 'invalid_refresh', __( 'Invalid refresh token.', 'akuko-mobile-api' ), array( 'status' => 401 ) );
		}

		$this->user_repository->revoke_refresh_token( $hash );
		return $this->issue_tokens( (int) $row['user_id'], $row['device_id'], $row['device_name'] );
	}

	public function me( int $user_id ): array {
		$user = $this->user_repository->find( $user_id );
		if ( ! $user ) {
			return array();
		}

		$profile = User_Transformer::from_wp_user( $user );
		$profile['sessions'] = $this->user_repository->get_device_sessions( $user_id );

		return $profile;
	}

	public function validate_access_token( string $token ): object {
		return JWT::decode( $token, new Key( $this->get_jwt_secret(), 'HS256' ) );
	}

	public function oauth_google( string $token ): array|\WP_Error {
		return new \WP_Error( 'not_implemented', __( 'Google OAuth not yet implemented.', 'akuko-mobile-api' ), array( 'status' => 501 ) );
	}

	public function oauth_apple( string $token ): array|\WP_Error {
		return new \WP_Error( 'not_implemented', __( 'Apple OAuth not yet implemented.', 'akuko-mobile-api' ), array( 'status' => 501 ) );
	}

	public function oauth_facebook( string $token ): array|\WP_Error {
		return new \WP_Error( 'not_implemented', __( 'Facebook OAuth not yet implemented.', 'akuko-mobile-api' ), array( 'status' => 501 ) );
	}

	private function issue_tokens( int $user_id, ?string $device_id, ?string $device_name ): array {
		$now     = time();
		$refresh = bin2hex( random_bytes( 32 ) );

		$access_payload = array(
			'iss' => home_url(),
			'sub' => $user_id,
			'iat' => $now,
			'exp' => $now + self::ACCESS_TTL,
		);

		$access_token = JWT::encode( $access_payload, $this->get_jwt_secret(), 'HS256' );

		$this->user_repository->store_refresh_token(
			$user_id,
			hash( 'sha256', $refresh ),
			gmdate( 'Y-m-d H:i:s', $now + self::REFRESH_TTL ),
			$device_id,
			$device_name
		);

		$user = $this->user_repository->find( $user_id );

		return array(
			'access_token'  => $access_token,
			'refresh_token' => $refresh,
			'expires_in'    => self::ACCESS_TTL,
			'token_type'    => 'Bearer',
			'user'          => $user ? User_Transformer::from_wp_user( $user ) : null,
		);
	}

	private function get_jwt_secret(): string {
		if ( defined( 'AKUKO_JWT_SECRET' ) ) {
			return AKUKO_JWT_SECRET;
		}

		$secret = get_option( 'akuko_jwt_secret' );
		if ( ! $secret ) {
			$secret = wp_generate_password( 64, true, true );
			update_option( 'akuko_jwt_secret', $secret, false );
		}

		return $secret;
	}
}
