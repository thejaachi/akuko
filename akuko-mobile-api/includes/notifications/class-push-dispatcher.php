<?php
/**
 * Push notification dispatch stubs.
 *
 * @package Akuko\MobileApi
 */

namespace Akuko\MobileApi\Notifications;

defined( 'ABSPATH' ) || exit;

class Push_Dispatcher {
	public static function send( int $user_id, string $title, string $body, array $data = array() ): void {
		do_action( 'akuko_mobile_api_push_send', $user_id, $title, $body, $data );
	}
}
