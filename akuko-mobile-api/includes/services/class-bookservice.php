<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Models\Book_Transformer;
use Akuko\MobileApi\Repositories\Interfaces\Book_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\BookService_Interface;
use Akuko\MobileApi\Services\Interfaces\CacheService_Interface;

defined( 'ABSPATH' ) || exit;

class BookService implements BookService_Interface {

	public function __construct(
		private Book_Repository_Interface $book_repository,
		private CacheService_Interface $cache
	) {}

	public function list_books( array $args ): array {
		$products = $this->book_repository->find_many( $args );
		$total    = $this->book_repository->count( $args );

		return array(
			'items' => Book_Transformer::collection( $products ),
			'total' => $total,
		);
	}

	public function get_book( int $id ): ?array {
		$product = $this->book_repository->find( $id );
		return $product ? Book_Transformer::from_product( $product ) : null;
	}

	public function get_featured( int $limit ): array {
		$key = 'akuko_featured_' . $limit;
		$cached = $this->cache->get( $key );
		if ( $cached ) {
			return $cached;
		}
		$data = Book_Transformer::collection( $this->book_repository->get_featured( $limit ) );
		$this->cache->set( $key, $data, 3600 );
		return $data;
	}

	public function get_trending( int $limit ): array {
		$key = 'akuko_trending_' . $limit;
		$cached = $this->cache->get( $key );
		if ( $cached ) {
			return $cached;
		}
		$data = Book_Transformer::collection( $this->book_repository->get_trending( $limit ) );
		$this->cache->set( $key, $data, 3600 );
		return $data;
	}

	public function get_new_releases( int $limit ): array {
		return Book_Transformer::collection( $this->book_repository->get_new_releases( $limit ) );
	}

	public function get_related( int $id, int $limit ): array {
		return Book_Transformer::collection( $this->book_repository->get_related( $id, $limit ) );
	}

	public function get_categories(): array {
		$cached = $this->cache->get( 'akuko_categories' );
		if ( $cached ) {
			return $cached;
		}

		$terms = $this->book_repository->get_categories();
		$data  = array();

		if ( ! is_wp_error( $terms ) ) {
			foreach ( $terms as $term ) {
				$data[] = array(
					'id'    => $term->term_id,
					'name'  => $term->name,
					'slug'  => $term->slug,
					'count' => $term->count,
					'image' => get_term_meta( $term->term_id, 'thumbnail_id', true )
						? wp_get_attachment_url( get_term_meta( $term->term_id, 'thumbnail_id', true ) )
						: '',
				);
			}
		}

		$this->cache->set( 'akuko_categories', $data, 3600 );
		return $data;
	}
}
