<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Services\Interfaces\AudiobookService_Interface;

defined( 'ABSPATH' ) || exit;

class AudiobookService implements AudiobookService_Interface {

	public function get_for_book( int $book_id, int $user_id ): array|\WP_Error {
		return array(
			'book_id'  => $book_id,
			'status'   => 'stub',
			'chapters' => array(),
			'message'  => __( 'Audiobook streaming will be available in a future release.', 'akuko-mobile-api' ),
		);
	}
}
