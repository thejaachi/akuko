<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Services\Interfaces\FeatureFlagService_Interface;

defined( 'ABSPATH' ) || exit;

class FeatureFlagService implements FeatureFlagService_Interface {

	public function get_all(): array {
		global $wpdb;
		return $wpdb->get_results(
			"SELECT flag_key, enabled, description, rollout_percent FROM {$wpdb->prefix}akuko_feature_flags ORDER BY flag_key ASC",
			ARRAY_A
		) ?: array();
	}

	public function is_enabled( string $key, ?int $user_id = null ): bool {
		global $wpdb;
		$row = $wpdb->get_row(
			$wpdb->prepare(
				"SELECT enabled, rollout_percent FROM {$wpdb->prefix}akuko_feature_flags WHERE flag_key = %s",
				$key
			),
			ARRAY_A
		);

		if ( ! $row || ! (int) $row['enabled'] ) {
			return false;
		}

		$rollout = (int) $row['rollout_percent'];
		if ( $rollout >= 100 ) {
			return true;
		}

		if ( null === $user_id ) {
			return false;
		}

		return ( $user_id % 100 ) < $rollout;
	}

	public function update( string $key, bool $enabled ): bool {
		global $wpdb;
		return (bool) $wpdb->update(
			"{$wpdb->prefix}akuko_feature_flags",
			array( 'enabled' => $enabled ? 1 : 0, 'updated_at' => current_time( 'mysql', true ) ),
			array( 'flag_key' => $key ),
			array( '%d', '%s' ),
			array( '%s' )
		);
	}
}
