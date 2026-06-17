<?php
namespace Akuko\MobileApi\Models;

defined( 'ABSPATH' ) || exit;

final class User_Transformer {

	public static function from_wp_user( \WP_User $user ): array {
		return array(
			'id'         => $user->ID,
			'email'      => $user->user_email,
			'username'   => $user->user_login,
			'first_name' => get_user_meta( $user->ID, 'first_name', true ),
			'last_name'  => get_user_meta( $user->ID, 'last_name', true ),
			'display_name' => $user->display_name,
			'avatar'     => get_avatar_url( $user->ID ),
			'registered' => $user->user_registered,
		);
	}
}
