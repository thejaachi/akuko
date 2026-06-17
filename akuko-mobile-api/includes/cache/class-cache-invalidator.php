<?php
namespace Akuko\MobileApi\Cache;

use Akuko\MobileApi\Services\Interfaces\CacheService_Interface;

defined( 'ABSPATH' ) || exit;

class Cache_Invalidator {

	public function __construct(
		private CacheService_Interface $cache
	) {}

	public function register(): void {
		add_action( 'save_post_product', array( $this, 'invalidate' ), 10, 1 );
		add_action( 'deleted_post', array( $this, 'invalidate' ), 10, 1 );
	}

	public function invalidate( int $post_id ): void {
		if ( 'product' !== get_post_type( $post_id ) ) {
			return;
		}

		$this->cache->flush_prefix( 'akuko_featured_' );
		$this->cache->flush_prefix( 'akuko_trending_' );
		$this->cache->delete( 'akuko_categories' );
	}
}
