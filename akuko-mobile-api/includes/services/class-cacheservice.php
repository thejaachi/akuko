<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Services\Interfaces\CacheService_Interface;

defined( 'ABSPATH' ) || exit;

class CacheService implements CacheService_Interface {

	private const PREFIX = 'akuko_cache_';

	public function get( string $key ): mixed {
		return get_transient( self::PREFIX . $key );
	}

	public function set( string $key, mixed $value, int $ttl = 3600 ): bool {
		return set_transient( self::PREFIX . $key, $value, $ttl );
	}

	public function delete( string $key ): bool {
		return delete_transient( self::PREFIX . $key );
	}

	public function flush_prefix( string $prefix ): void {
		global $wpdb;
		$like = '_transient_' . self::PREFIX . $prefix . '%';
		$wpdb->query(
			$wpdb->prepare(
				"DELETE FROM {$wpdb->options} WHERE option_name LIKE %s OR option_name LIKE %s",
				$like,
				'_transient_timeout_' . self::PREFIX . $prefix . '%'
			)
		);
	}
}
