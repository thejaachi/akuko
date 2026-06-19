<?php
if ( ! class_exists( 'WP_User' ) ) {
	class WP_User {
		public int $ID = 0;
		public string $user_pass = '';
		public string $user_login = '';
		public string $user_email = '';
		public string $display_name = '';
		public string $user_registered = '';
	}
}

if ( ! function_exists( 'wp_hash_password' ) ) {
	function wp_hash_password( string $password ): string {
		return password_hash( $password, PASSWORD_BCRYPT );
	}
}

if ( ! function_exists( 'wp_check_password' ) ) {
	function wp_check_password( string $password, string $hash, int $user_id ): bool {
		return password_verify( $password, $hash );
	}
}

if ( ! function_exists( 'home_url' ) ) {
	function home_url( string $path = '' ): string {
		return 'https://example.test' . $path;
	}
}

if ( ! function_exists( 'get_option' ) ) {
	function get_option( string $option, mixed $default = false ): mixed {
		return $default;
	}
}

if ( ! function_exists( 'update_option' ) ) {
	function update_option( string $option, mixed $value, bool $autoload = true ): bool {
		return true;
	}
}

if ( ! function_exists( 'wp_generate_password' ) ) {
	function wp_generate_password( int $length = 12, bool $special_chars = true, bool $extra_special_chars = false ): string {
		return str_repeat( 'x', $length );
	}
}

if ( ! function_exists( 'get_user_meta' ) ) {
	function get_user_meta( int $user_id, string $key, bool $single = false ): mixed {
		return $single ? '' : array();
	}
}

if ( ! function_exists( 'get_avatar_url' ) ) {
	function get_avatar_url( int $user_id ): string {
		return 'https://example.test/avatar.png';
	}
}

if ( ! function_exists( 'current_time' ) ) {
	function current_time( string $type, bool $gmt = false ): string {
		return gmdate( 'Y-m-d H:i:s' );
	}
}
