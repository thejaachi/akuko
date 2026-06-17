<?php
if ( ! class_exists( 'WP_REST_Request' ) ) {
	class WP_REST_Request {
		/**
		 * @param array<string, mixed> $params Request parameters.
		 */
		public function __construct( private array $params = array() ) {}

		public function get_param( string $key ): mixed {
			return $this->params[ $key ] ?? null;
		}
	}
}

if ( ! class_exists( 'WP_REST_Response' ) ) {
	class WP_REST_Response {
		/**
		 * @param array<string, mixed> $data   Response body.
		 * @param int                  $status HTTP status.
		 */
		public function __construct( public array $data, public int $status ) {}
	}
}

if ( ! function_exists( 'sanitize_email' ) ) {
	function sanitize_email( string $email ): string {
		return trim( $email );
	}
}

if ( ! function_exists( 'sanitize_text_field' ) ) {
	function sanitize_text_field( string $text ): string {
		return trim( $text );
	}
}

if ( ! function_exists( 'get_transient' ) ) {
	function get_transient( string $key ): mixed {
		return false;
	}
}

if ( ! function_exists( 'set_transient' ) ) {
	function set_transient( string $key, mixed $value, int $expiration ): bool {
		return true;
	}
}

if ( ! function_exists( 'wp_unslash' ) ) {
	function wp_unslash( mixed $value ): mixed {
		return $value;
	}
}

if ( ! function_exists( 'is_wp_error' ) ) {
	function is_wp_error( mixed $thing ): bool {
		return $thing instanceof \WP_Error;
	}
}
