<?php
namespace Akuko\MobileApi\Repositories;

use Akuko\MobileApi\Repositories\Interfaces\Review_Repository_Interface;

defined( 'ABSPATH' ) || exit;

class Review_Repository implements Review_Repository_Interface {

	public function get_for_product( int $product_id, int $limit, int $offset ): array {
		$comments = get_comments( array(
			'post_id' => $product_id,
			'status'  => 'approve',
			'type'    => 'review',
			'number'  => $limit,
			'offset'  => $offset,
		) );

		return array_map( array( $this, 'transform' ), $comments );
	}

	public function count_for_product( int $product_id ): int {
		return (int) get_comments( array(
			'post_id' => $product_id,
			'status'  => 'approve',
			'type'    => 'review',
			'count'   => true,
		) );
	}

	public function create( int $product_id, int $user_id, array $data ): int|\WP_Error {
		$comment_id = wp_insert_comment( array(
			'comment_post_ID'      => $product_id,
			'comment_author'       => wp_get_current_user()->display_name,
			'comment_author_email' => wp_get_current_user()->user_email,
			'comment_content'      => sanitize_textarea_field( $data['content'] ?? '' ),
			'comment_type'         => 'review',
			'user_id'              => $user_id,
			'comment_approved'     => 0,
		) );

		if ( ! $comment_id ) {
			return new \WP_Error( 'review_failed', __( 'Could not submit review.', 'akuko-mobile-api' ) );
		}

		if ( isset( $data['rating'] ) ) {
			update_comment_meta( $comment_id, 'rating', (int) $data['rating'] );
		}

		return $comment_id;
	}

	private function transform( \WP_Comment $comment ): array {
		return array(
			'id'      => (int) $comment->comment_ID,
			'user_id' => (int) $comment->user_id,
			'author'  => $comment->comment_author,
			'content' => $comment->comment_content,
			'rating'  => (int) get_comment_meta( $comment->comment_ID, 'rating', true ),
			'date'    => $comment->comment_date_gmt,
		);
	}
}
