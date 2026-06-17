<?php
namespace Akuko\MobileApi\Services;

use Akuko\MobileApi\Services\Interfaces\SettingsService_Interface;

defined( 'ABSPATH' ) || exit;

class SettingsService implements SettingsService_Interface {

	public function get_public_settings(): array {
		return array(
			'site_name'        => get_bloginfo( 'name' ),
			'site_url'         => home_url(),
			'currency'         => get_woocommerce_currency(),
			'currency_symbol'  => get_woocommerce_currency_symbol(),
			'support_email'    => get_option( 'akuko_support_email', get_option( 'admin_email' ) ),
			'premium_price'    => (float) get_option( 'akuko_premium_price', 9999 ),
			'min_app_version'  => get_option( 'akuko_min_app_version', '1.0.0' ),
			'terms_url'        => get_option( 'akuko_terms_url', '' ),
			'privacy_url'      => get_option( 'akuko_privacy_url', '' ),
		);
	}
}
