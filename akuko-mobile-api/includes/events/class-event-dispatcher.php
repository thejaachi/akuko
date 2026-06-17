<?php
namespace Akuko\MobileApi\Events;

defined( 'ABSPATH' ) || exit;

class Event_Dispatcher {

	/**
	 * @param string               $event  Event name.
	 * @param array<string, mixed> $payload Event data.
	 */
	public function dispatch( string $event, array $payload = array() ): void {
		do_action( 'akuko_mobile_api_' . $event, $payload );
		do_action( 'akuko_mobile_api_event', $event, $payload );
	}
}
