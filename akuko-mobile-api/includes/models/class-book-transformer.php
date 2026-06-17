<?php
namespace Akuko\MobileApi\Models;

defined( 'ABSPATH' ) || exit;

/**
 * Transforms WC_Product to mobile-friendly DTO.
 */
final class Book_Transformer {

	public static function from_product( \WC_Product $product ): array {
		$author_id = (int) get_post_meta( $product->get_id(), '_akuko_author_id', true );
		$gallery   = array();

		foreach ( $product->get_gallery_image_ids() as $image_id ) {
			$url = wp_get_attachment_url( $image_id );
			if ( $url ) {
				$gallery[] = $url;
			}
		}

		$formats = array();
		if ( $product->is_downloadable() ) {
			foreach ( $product->get_downloads() as $download ) {
				$ext = pathinfo( $download->get_file(), PATHINFO_EXTENSION );
				$formats[] = strtolower( $ext ?: 'epub' );
			}
		}
		if ( empty( $formats ) ) {
			$formats = array( 'epub', 'pdf' );
		}

		$categories = array();
		foreach ( $product->get_category_ids() as $cat_id ) {
			$term = get_term( $cat_id, 'product_cat' );
			if ( $term && ! is_wp_error( $term ) ) {
				$categories[] = array(
					'id'   => $term->term_id,
					'name' => $term->name,
					'slug' => $term->slug,
				);
			}
		}

		return array(
			'id'           => $product->get_id(),
			'title'        => $product->get_name(),
			'subtitle'     => get_post_meta( $product->get_id(), '_akuko_subtitle', true ) ?: '',
			'description'  => wp_strip_all_tags( $product->get_description() ),
			'short_description' => wp_strip_all_tags( $product->get_short_description() ),
			'cover'        => wp_get_attachment_url( $product->get_image_id() ) ?: '',
			'gallery'      => $gallery,
			'isbn'         => get_post_meta( $product->get_id(), '_akuko_isbn', true ) ?: '',
			'language'     => get_post_meta( $product->get_id(), '_akuko_language', true ) ?: 'en',
			'pages'        => (int) get_post_meta( $product->get_id(), '_akuko_pages', true ),
			'author_id'    => $author_id,
			'author_name'  => $author_id ? get_the_author_meta( 'display_name', $author_id ) : '',
			'genres'       => $categories,
			'formats'      => array_values( array_unique( $formats ) ),
			'price'        => (float) $product->get_price(),
			'regular_price'=> (float) $product->get_regular_price(),
			'sale_price'   => $product->get_sale_price() ? (float) $product->get_sale_price() : null,
			'currency'     => get_woocommerce_currency(),
			'rating'       => (float) $product->get_average_rating(),
			'review_count' => (int) $product->get_review_count(),
			'featured'     => $product->is_featured(),
			'date'         => $product->get_date_created()?->format( 'c' ),
			'slug'         => $product->get_slug(),
		);
	}

	/**
	 * @param \WC_Product[] $products Products.
	 * @return array<int, array<string, mixed>>
	 */
	public static function collection( array $products ): array {
		return array_values( array_map( array( self::class, 'from_product' ), $products ) );
	}
}
