<?php
if ( ! function_exists( 'sanitize_email' ) ) {
	function sanitize_email( string $email ): string {
		return filter_var( trim( $email ), FILTER_SANITIZE_EMAIL ) ?: '';
	}
}

if ( ! function_exists( 'is_email' ) ) {
	function is_email( string $email ): bool {
		return false !== filter_var( $email, FILTER_VALIDATE_EMAIL );
	}
}

if ( ! function_exists( 'sanitize_text_field' ) ) {
	function sanitize_text_field( string $text ): string {
		return trim( $text );
	}
}

if ( ! function_exists( 'email_exists' ) ) {
	function email_exists( string $email ): bool {
		return false;
	}
}

if ( ! function_exists( 'get_user_by' ) ) {
	function get_user_by( string $field, string $value ): ?\WP_User {
		return null;
	}
}

if ( ! function_exists( 'wp_create_user' ) ) {
	function wp_create_user( string $username, string $password, string $email ): int|\WP_Error {
		return 1;
	}
}

if ( ! function_exists( 'update_user_meta' ) ) {
	function update_user_meta( int $user_id, string $key, mixed $value ): bool {
		return true;
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

if ( ! function_exists( 'wp_remote_get' ) ) {
	function wp_remote_get( string $url, array $args = array() ): array|\WP_Error {
		return new \WP_Error( 'http_request_failed', 'Unavailable in test stub.' );
	}
}

if ( ! function_exists( 'wp_remote_retrieve_response_code' ) ) {
	function wp_remote_retrieve_response_code( array $response ): int {
		return 0;
	}
}

if ( ! function_exists( 'wp_remote_retrieve_body' ) ) {
	function wp_remote_retrieve_body( array $response ): string {
		return '';
	}
}
