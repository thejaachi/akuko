<?php
namespace Akuko\MobileApi\Controllers;

use Akuko\MobileApi\Middleware\Jwt_Auth_Middleware;
use Akuko\MobileApi\Middleware\Rate_Limit_Middleware;
use Akuko\MobileApi\Services\Interfaces\AuthenticationService_Interface;
use Akuko\MobileApi\Validators\Auth_Validator;

defined( 'ABSPATH' ) || exit;

class Auth_Controller extends Base_Controller {

	public function __construct(
		Jwt_Auth_Middleware $jwt,
		Rate_Limit_Middleware $rate_limit,
		private AuthenticationService_Interface $auth
	) {
		parent::__construct( $jwt, $rate_limit );
	}

	public function register( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->rate_limit_check( $request );
		if ( is_wp_error( $check ) ) {
			return $this->from_wp_error( $check );
		}

		$email    = sanitize_email( (string) ( $request->get_param( 'email' ) ?? '' ) );
		$password = $request->get_param( 'password' );
		$first    = sanitize_text_field( (string) ( $request->get_param( 'first_name' ) ?? '' ) );
		$last     = sanitize_text_field( (string) ( $request->get_param( 'last_name' ) ?? '' ) );
		$name     = sanitize_text_field( (string) ( $request->get_param( 'name' ) ?? '' ) );

		if ( '' === $first && '' !== $name ) {
			$parts = preg_split( '/\s+/', trim( $name ), 2 );
			$first = $parts[0] ?? '';
			$last  = $parts[1] ?? '';
		}

		$error = Auth_Validator::registration( array(
			'email'    => $email,
			'password' => is_string( $password ) ? $password : '',
		) );
		if ( null !== $error ) {
			return $this->error( $error, 'invalid_data', 400 );
		}

		$result = $this->auth->register( array(
			'email'       => $email,
			'password'    => $password,
			'first_name'  => $first,
			'last_name'   => $last,
			'device_id'   => sanitize_text_field( $request->get_param( 'device_id' ) ?? '' ),
			'device_name' => sanitize_text_field( $request->get_param( 'device_name' ) ?? '' ),
		) );

		return is_wp_error( $result ) ? $this->from_wp_error( $result ) : $this->success( $result, array(), 201 );
	}

	public function login( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->rate_limit_check( $request );
		if ( is_wp_error( $check ) ) {
			return $this->from_wp_error( $check );
		}

		$email    = sanitize_email( (string) ( $request->get_param( 'email' ) ?? '' ) );
		$password = $request->get_param( 'password' );
		$error    = Auth_Validator::login_credentials( array(
			'email'    => $email,
			'password' => is_string( $password ) ? $password : '',
		) );
		if ( null !== $error ) {
			return $this->error( $error, 'invalid_data', 400 );
		}

		$result = $this->auth->login(
			$email,
			$password,
			sanitize_text_field( $request->get_param( 'device_id' ) ?? '' ),
			sanitize_text_field( $request->get_param( 'device_name' ) ?? '' )
		);

		return is_wp_error( $result ) ? $this->from_wp_error( $result ) : $this->success( $result );
	}

	public function logout( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) {
			return $this->from_wp_error( $check );
		}

		$this->auth->logout( get_current_user_id(), $request->get_param( 'refresh_token' ) );
		return $this->success( array( 'logged_out' => true ) );
	}

	public function forgot_password( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->rate_limit_check( $request );
		if ( is_wp_error( $check ) ) {
			return $this->from_wp_error( $check );
		}

		$result = $this->auth->forgot_password( sanitize_email( $request->get_param( 'email' ) ) );
		return is_wp_error( $result ) ? $this->from_wp_error( $result ) : $this->success( array( 'sent' => true ) );
	}

	public function reset_password( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->rate_limit_check( $request );
		if ( is_wp_error( $check ) ) {
			return $this->from_wp_error( $check );
		}

		$result = $this->auth->reset_password(
			sanitize_text_field( $request->get_param( 'token' ) ),
			$request->get_param( 'password' )
		);

		return is_wp_error( $result ) ? $this->from_wp_error( $result ) : $this->success( array( 'reset' => true ) );
	}

	public function refresh( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->rate_limit_check( $request );
		if ( is_wp_error( $check ) ) {
			return $this->from_wp_error( $check );
		}

		$result = $this->auth->refresh( sanitize_text_field( $request->get_param( 'refresh_token' ) ) );
		return is_wp_error( $result ) ? $this->from_wp_error( $result ) : $this->success( $result );
	}

	public function me( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) {
			return $this->from_wp_error( $check );
		}

		return $this->success( $this->auth->me( get_current_user_id() ) );
	}
}
