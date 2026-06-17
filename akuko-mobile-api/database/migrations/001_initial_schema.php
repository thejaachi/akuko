<?php
/**
 * Initial database schema migration.
 *
 * @package Akuko\MobileApi
 */

namespace Akuko\MobileApi\Database\Migrations;

defined( 'ABSPATH' ) || exit;

/**
 * Creates custom tables via dbDelta.
 */
final class Initial_Schema {

	/**
	 * Run migration.
	 */
	public static function run(): void {
		global $wpdb;

		require_once ABSPATH . 'wp-admin/includes/upgrade.php';

		$charset = $wpdb->get_charset_collate();
		$prefix  = $wpdb->prefix . 'akuko_';

		$tables = array(
			"CREATE TABLE {$prefix}reading_progress (
				id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
				user_id bigint(20) unsigned NOT NULL,
				book_id bigint(20) unsigned NOT NULL,
				position varchar(50) NOT NULL DEFAULT '0',
				percentage decimal(5,2) NOT NULL DEFAULT 0.00,
				chapter varchar(255) DEFAULT NULL,
				updated_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
				PRIMARY KEY (id),
				UNIQUE KEY user_book (user_id, book_id),
				KEY book_id (book_id)
			) $charset;",

			"CREATE TABLE {$prefix}reading_statistics (
				id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
				user_id bigint(20) unsigned NOT NULL,
				book_id bigint(20) unsigned NOT NULL,
				total_seconds int unsigned NOT NULL DEFAULT 0,
				sessions int unsigned NOT NULL DEFAULT 0,
				last_read_at datetime DEFAULT NULL,
				PRIMARY KEY (id),
				UNIQUE KEY user_book (user_id, book_id)
			) $charset;",

			"CREATE TABLE {$prefix}book_highlights (
				id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
				user_id bigint(20) unsigned NOT NULL,
				book_id bigint(20) unsigned NOT NULL,
				text longtext NOT NULL,
				cfi varchar(255) DEFAULT NULL,
				color varchar(20) DEFAULT '#FFEB3B',
				created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
				PRIMARY KEY (id),
				KEY user_book (user_id, book_id)
			) $charset;",

			"CREATE TABLE {$prefix}book_notes (
				id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
				user_id bigint(20) unsigned NOT NULL,
				book_id bigint(20) unsigned NOT NULL,
				content longtext NOT NULL,
				cfi varchar(255) DEFAULT NULL,
				created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
				updated_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
				PRIMARY KEY (id),
				KEY user_book (user_id, book_id)
			) $charset;",

			"CREATE TABLE {$prefix}reading_history (
				id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
				user_id bigint(20) unsigned NOT NULL,
				book_id bigint(20) unsigned NOT NULL,
				opened_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
				PRIMARY KEY (id),
				KEY user_id (user_id),
				KEY opened_at (opened_at)
			) $charset;",

			"CREATE TABLE {$prefix}subscriptions (
				id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
				user_id bigint(20) unsigned NOT NULL,
				plan varchar(50) NOT NULL DEFAULT 'premium',
				status varchar(20) NOT NULL DEFAULT 'active',
				paystack_reference varchar(100) DEFAULT NULL,
				starts_at datetime NOT NULL,
				expires_at datetime DEFAULT NULL,
				created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
				PRIMARY KEY (id),
				KEY user_id (user_id),
				KEY status (status)
			) $charset;",

			"CREATE TABLE {$prefix}downloads (
				id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
				user_id bigint(20) unsigned NOT NULL,
				book_id bigint(20) unsigned NOT NULL,
				format varchar(20) NOT NULL DEFAULT 'epub',
				token_hash varchar(64) NOT NULL,
				expires_at datetime NOT NULL,
				downloaded_at datetime DEFAULT NULL,
				created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
				PRIMARY KEY (id),
				KEY token_hash (token_hash),
				KEY user_book (user_id, book_id)
			) $charset;",

			"CREATE TABLE {$prefix}api_logs (
				id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
				user_id bigint(20) unsigned DEFAULT NULL,
				endpoint varchar(255) NOT NULL,
				method varchar(10) NOT NULL,
				ip_address varchar(45) DEFAULT NULL,
				status_code smallint unsigned NOT NULL DEFAULT 200,
				request_body longtext,
				created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
				PRIMARY KEY (id),
				KEY created_at (created_at),
				KEY endpoint (endpoint)
			) $charset;",

			"CREATE TABLE {$prefix}notifications (
				id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
				user_id bigint(20) unsigned NOT NULL,
				type varchar(50) NOT NULL,
				title varchar(255) NOT NULL,
				body text,
				data longtext,
				read_at datetime DEFAULT NULL,
				created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
				PRIMARY KEY (id),
				KEY user_id (user_id),
				KEY read_at (read_at)
			) $charset;",

			"CREATE TABLE {$prefix}feature_flags (
				id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
				flag_key varchar(100) NOT NULL,
				enabled tinyint(1) NOT NULL DEFAULT 0,
				description text,
				rollout_percent tinyint unsigned NOT NULL DEFAULT 100,
				updated_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
				PRIMARY KEY (id),
				UNIQUE KEY flag_key (flag_key)
			) $charset;",

			"CREATE TABLE {$prefix}refresh_tokens (
				id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
				user_id bigint(20) unsigned NOT NULL,
				token_hash varchar(64) NOT NULL,
				device_id varchar(255) DEFAULT NULL,
				device_name varchar(255) DEFAULT NULL,
				expires_at datetime NOT NULL,
				revoked_at datetime DEFAULT NULL,
				created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
				PRIMARY KEY (id),
				UNIQUE KEY token_hash (token_hash),
				KEY user_id (user_id)
			) $charset;",

			"CREATE TABLE {$prefix}bookmarks (
				id bigint(20) unsigned NOT NULL AUTO_INCREMENT,
				user_id bigint(20) unsigned NOT NULL,
				book_id bigint(20) unsigned NOT NULL,
				cfi varchar(255) NOT NULL,
				label varchar(255) DEFAULT NULL,
				created_at datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
				PRIMARY KEY (id),
				KEY user_book (user_id, book_id)
			) $charset;",
		);

		foreach ( $tables as $sql ) {
			dbDelta( $sql );
		}

		self::seed_feature_flags( $prefix );
		update_option( 'akuko_mobile_api_db_version', '1.0.0' );
	}

	/**
	 * Seed default feature flags.
	 *
	 * @param string $prefix Table prefix.
	 */
	private static function seed_feature_flags( string $prefix ): void {
		global $wpdb;

		$defaults = array(
			array( 'ai_chat', 0, 'AI chat assistant' ),
			array( 'ai_summary', 0, 'AI book summaries' ),
			array( 'audiobooks', 1, 'Audiobook streaming' ),
			array( 'offline_sync', 1, 'Cross-device reading sync' ),
			array( 'premium_themes', 1, 'Premium reader themes' ),
		);

		foreach ( $defaults as $flag ) {
			$exists = $wpdb->get_var(
				$wpdb->prepare(
					"SELECT id FROM {$prefix}feature_flags WHERE flag_key = %s",
					$flag[0]
				)
			);

			if ( ! $exists ) {
				$wpdb->insert(
					"{$prefix}feature_flags",
					array(
						'flag_key'    => $flag[0],
						'enabled'     => $flag[1],
						'description' => $flag[2],
					),
					array( '%s', '%d', '%s' )
				);
			}
		}
	}
}
