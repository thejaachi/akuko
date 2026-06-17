<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Models\User_Transformer;
use Akuko\MobileApi\Repositories\Interfaces\User_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\UserService_Interface;

defined( 'ABSPATH' ) || exit;

class UserService implements UserService_Interface {

	public function __construct(
		private User_Repository_Interface $user_repository
	) {}

	public function get_profile( int $user_id ): array {
		$user = $this->user_repository->find( $user_id );
		return $user ? User_Transformer::from_wp_user( $user ) : array();
	}
}
