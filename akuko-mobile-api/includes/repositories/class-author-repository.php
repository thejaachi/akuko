<?php
namespace Akuko\MobileApi\Repositories;

use Akuko\MobileApi\Repositories\Interfaces\Author_Repository_Interface;

defined( 'ABSPATH' ) || exit;

class Author_Repository implements Author_Repository_Interface {

	public function find( int $id ): ?array {
		$user = get_user_by( 'id', $id );
		if ( ! $user || ! $this->is_vendor( $id ) ) {
			return null;
		}
		return $this->transform_vendor( $user );
	}

	public function find_many( array $args ): array {
		$limit  = (int) ( $args['limit'] ?? 20 );
		$offset = (int) ( $args['offset'] ?? 0 );

		$vendors = get_users( array(
			'role'   => 'seller',
			'number' => $limit,
			'offset' => $offset,
			'orderby'=> 'display_name',
		) );

		return array_map( fn( $u ) => $this->transform_vendor( $u ), $vendors );
	}

	public function count( array $args ): int {
		$users = count_users();
		return (int) ( $users['avail_roles']['seller'] ?? 0 );
	}

	private function is_vendor( int $id ): bool {
		if ( function_exists( 'dokan_is_user_seller' ) ) {
			return dokan_is_user_seller( $id );
		}
		$user = get_userdata( $id );
		return $user && in_array( 'seller', (array) $user->roles, true );
	}

	private function transform_vendor( \WP_User $user ): array {
		$store_name = get_user_meta( $user->ID, 'dokan_store_name', true );
		return array(
			'id'          => $user->ID,
			'name'        => $store_name ?: $user->display_name,
			'slug'        => $user->user_nicename,
			'avatar'      => get_avatar_url( $user->ID ),
			'description' => get_user_meta( $user->ID, 'description', true ),
		);
	}
}
