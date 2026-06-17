<?php
namespace Akuko\MobileApi\Admin;

use Akuko\MobileApi\Plugin;
use Akuko\MobileApi\Repositories\Interfaces\Analytics_Repository_Interface;
use Akuko\MobileApi\Repositories\Interfaces\Subscription_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\FeatureFlagService_Interface;

defined( 'ABSPATH' ) || exit;

class Admin_Menu {

	public function register(): void {
		add_action( 'admin_menu', array( $this, 'add_menus' ) );
		add_action( 'admin_enqueue_scripts', array( $this, 'enqueue_assets' ) );
		add_action( 'admin_post_akuko_toggle_flag', array( $this, 'handle_toggle_flag' ) );
	}

	public function add_menus(): void {
		add_menu_page(
			__( 'Akuko Mobile', 'akuko-mobile-api' ),
			__( 'Akuko Mobile', 'akuko-mobile-api' ),
			'manage_options',
			'akuko-mobile',
			array( $this, 'render_dashboard' ),
			'dashicons-smartphone',
			58
		);

		$subpages = array(
			'akuko-mobile'           => array( __( 'Dashboard', 'akuko-mobile-api' ), 'render_dashboard' ),
			'akuko-mobile-monitor'   => array( __( 'API Monitor', 'akuko-mobile-api' ), 'render_monitor' ),
			'akuko-mobile-premium'   => array( __( 'Premium Members', 'akuko-mobile-api' ), 'render_premium' ),
			'akuko-mobile-flags'     => array( __( 'Feature Flags', 'akuko-mobile-api' ), 'render_flags' ),
			'akuko-mobile-settings'  => array( __( 'Settings', 'akuko-mobile-api' ), 'render_settings' ),
			'akuko-mobile-logs'      => array( __( 'Logs', 'akuko-mobile-api' ), 'render_logs' ),
		);

		foreach ( $subpages as $slug => $page ) {
			add_submenu_page(
				'akuko-mobile',
				$page[0],
				$page[0],
				'manage_options',
				$slug,
				array( $this, $page[1] )
			);
		}
	}

	public function enqueue_assets( string $hook ): void {
		if ( ! str_contains( $hook, 'akuko-mobile' ) ) {
			return;
		}
		wp_enqueue_style( 'akuko-admin', AKUKO_MOBILE_API_URL . 'assets/css/admin.css', array(), AKUKO_MOBILE_API_VERSION );
	}

	public function render_dashboard(): void {
		$this->wrap( __( 'Dashboard', 'akuko-mobile-api' ), function () {
			echo '<p>' . esc_html__( 'Akuko Mobile API BFF is active.', 'akuko-mobile-api' ) . '</p>';
			echo '<p><strong>' . esc_html__( 'API Base:', 'akuko-mobile-api' ) . '</strong> <code>' . esc_url( rest_url( 'akuko/v1' ) ) . '</code></p>';
			echo '<p><strong>' . esc_html__( 'Version:', 'akuko-mobile-api' ) . '</strong> ' . esc_html( AKUKO_MOBILE_API_VERSION ) . '</p>';
		} );
	}

	public function render_monitor(): void {
		$this->wrap( __( 'API Monitor', 'akuko-mobile-api' ), function () {
			echo '<p>' . esc_html__( 'Monitor API health and request volume from the Logs page.', 'akuko-mobile-api' ) . '</p>';
		} );
	}

	public function render_premium(): void {
		global $wpdb;
		$this->wrap( __( 'Premium Members', 'akuko-mobile-api' ), function () use ( $wpdb ) {
			$rows = $wpdb->get_results(
				"SELECT s.*, u.user_email FROM {$wpdb->prefix}akuko_subscriptions s LEFT JOIN {$wpdb->users} u ON u.ID = s.user_id WHERE s.status = 'active' ORDER BY s.created_at DESC LIMIT 50",
				ARRAY_A
			);
			echo '<table class="widefat"><thead><tr><th>User</th><th>Plan</th><th>Expires</th><th>Reference</th></tr></thead><tbody>';
			foreach ( $rows ?: array() as $row ) {
				printf(
					'<tr><td>%s</td><td>%s</td><td>%s</td><td>%s</td></tr>',
					esc_html( $row['user_email'] ?? '#' . $row['user_id'] ),
					esc_html( $row['plan'] ),
					esc_html( $row['expires_at'] ?? '—' ),
					esc_html( $row['paystack_reference'] ?? '—' )
				);
			}
			echo '</tbody></table>';
		} );
	}

	public function render_flags(): void {
		$flags = Plugin::instance()->container()->get( FeatureFlagService_Interface::class )->get_all();
		$this->wrap( __( 'Feature Flags', 'akuko-mobile-api' ), function () use ( $flags ) {
			echo '<table class="widefat"><thead><tr><th>Flag</th><th>Description</th><th>Rollout</th><th>Status</th><th>Action</th></tr></thead><tbody>';
			foreach ( $flags as $flag ) {
				$enabled = (int) $flag['enabled'];
				printf(
					'<tr><td><code>%s</code></td><td>%s</td><td>%d%%</td><td>%s</td><td>
					<form method="post" action="%s" style="display:inline">
					%s<input type="hidden" name="flag_key" value="%s" />
					<input type="hidden" name="enabled" value="%d" />
					<button class="button">%s</button></form></td></tr>',
					esc_html( $flag['flag_key'] ),
					esc_html( $flag['description'] ?? '' ),
					(int) $flag['rollout_percent'],
					$enabled ? esc_html__( 'Enabled', 'akuko-mobile-api' ) : esc_html__( 'Disabled', 'akuko-mobile-api' ),
					esc_url( admin_url( 'admin-post.php?action=akuko_toggle_flag' ) ),
					wp_nonce_field( 'akuko_toggle_flag', '_wpnonce', true, false ),
					esc_attr( $flag['flag_key'] ),
					$enabled ? 0 : 1,
					$enabled ? esc_html__( 'Disable', 'akuko-mobile-api' ) : esc_html__( 'Enable', 'akuko-mobile-api' )
				);
			}
			echo '</tbody></table>';
		} );
	}

	public function render_settings(): void {
		if ( isset( $_POST['akuko_settings_nonce'] ) && wp_verify_nonce( sanitize_text_field( wp_unslash( $_POST['akuko_settings_nonce'] ) ), 'akuko_settings' ) ) {
			update_option( 'akuko_support_email', sanitize_email( wp_unslash( $_POST['akuko_support_email'] ?? '' ) ) );
			update_option( 'akuko_premium_price', (float) ( $_POST['akuko_premium_price'] ?? 0 ) );
			echo '<div class="notice notice-success"><p>' . esc_html__( 'Settings saved.', 'akuko-mobile-api' ) . '</p></div>';
		}

		$this->wrap( __( 'Settings', 'akuko-mobile-api' ), function () {
			?>
			<form method="post">
				<?php wp_nonce_field( 'akuko_settings', 'akuko_settings_nonce' ); ?>
				<table class="form-table">
					<tr><th><?php esc_html_e( 'Support Email', 'akuko-mobile-api' ); ?></th>
						<td><input type="email" name="akuko_support_email" value="<?php echo esc_attr( get_option( 'akuko_support_email', get_option( 'admin_email' ) ) ); ?>" class="regular-text" /></td></tr>
					<tr><th><?php esc_html_e( 'Premium Price (minor units)', 'akuko-mobile-api' ); ?></th>
						<td><input type="number" name="akuko_premium_price" value="<?php echo esc_attr( get_option( 'akuko_premium_price', 9999 ) ); ?>" /></td></tr>
					<tr><th><?php esc_html_e( 'Paystack Secret', 'akuko-mobile-api' ); ?></th>
						<td><code>AKUKO_PAYSTACK_SECRET_KEY</code> <?php esc_html_e( 'in wp-config.php (recommended) or akuko_paystack_secret_key option.', 'akuko-mobile-api' ); ?></td></tr>
				</table>
				<?php submit_button(); ?>
			</form>
			<?php
		} );
	}

	public function render_logs(): void {
		$repo = Plugin::instance()->container()->get( Analytics_Repository_Interface::class );
		$logs = $repo->get_api_logs( 100, 0 );
		$this->wrap( __( 'API Logs', 'akuko-mobile-api' ), function () use ( $logs ) {
			echo '<table class="widefat"><thead><tr><th>Time</th><th>Method</th><th>Endpoint</th><th>Status</th><th>IP</th></tr></thead><tbody>';
			foreach ( $logs as $log ) {
				printf(
					'<tr><td>%s</td><td>%s</td><td><code>%s</code></td><td>%d</td><td>%s</td></tr>',
					esc_html( $log['created_at'] ),
					esc_html( $log['method'] ),
					esc_html( $log['endpoint'] ),
					(int) $log['status_code'],
					esc_html( $log['ip_address'] ?? '' )
				);
			}
			echo '</tbody></table>';
		} );
	}

	public function handle_toggle_flag(): void {
		check_admin_referer( 'akuko_toggle_flag' );
		if ( ! current_user_can( 'manage_options' ) ) {
			wp_die( esc_html__( 'Unauthorized', 'akuko-mobile-api' ) );
		}
		$key     = sanitize_text_field( wp_unslash( $_POST['flag_key'] ?? '' ) );
		$enabled = (bool) ( $_POST['enabled'] ?? 0 );
		Plugin::instance()->container()->get( FeatureFlagService_Interface::class )->update( $key, $enabled );
		wp_safe_redirect( admin_url( 'admin.php?page=akuko-mobile-flags' ) );
		exit;
	}

	private function wrap( string $title, callable $callback ): void {
		echo '<div class="wrap akuko-admin"><h1>' . esc_html( $title ) . '</h1>';
		$callback();
		echo '</div>';
	}
}
