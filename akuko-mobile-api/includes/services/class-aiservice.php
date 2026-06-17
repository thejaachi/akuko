<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Services\Interfaces\AIService_Interface;

defined( 'ABSPATH' ) || exit;

class AIService implements AIService_Interface {

	public function summary( int $book_id, int $user_id ): array|\WP_Error {
		return new \WP_Error( 'not_implemented', __( 'AI summary not yet implemented.', 'akuko-mobile-api' ), array( 'status' => 501 ) );
	}

	public function chat( int $user_id, array $messages ): array|\WP_Error {
		return new \WP_Error( 'not_implemented', __( 'AI chat not yet implemented.', 'akuko-mobile-api' ), array( 'status' => 501 ) );
	}
}
