<?php
namespace Akuko\MobileApi\Api;

use Akuko\MobileApi\Container;
use Akuko\MobileApi\Controllers\AI_Controller;
use Akuko\MobileApi\Controllers\Analytics_Controller;
use Akuko\MobileApi\Controllers\Auth_Controller;
use Akuko\MobileApi\Controllers\Authors_Controller;
use Akuko\MobileApi\Controllers\Audiobooks_Controller;
use Akuko\MobileApi\Controllers\Books_Controller;
use Akuko\MobileApi\Controllers\Downloads_Controller;
use Akuko\MobileApi\Controllers\Feature_Flags_Controller;
use Akuko\MobileApi\Controllers\Library_Controller;
use Akuko\MobileApi\Controllers\Notifications_Controller;
use Akuko\MobileApi\Controllers\Payments_Controller;
use Akuko\MobileApi\Controllers\Premium_Controller;
use Akuko\MobileApi\Controllers\Reading_Controller;
use Akuko\MobileApi\Controllers\Recommendations_Controller;
use Akuko\MobileApi\Controllers\Reviews_Controller;
use Akuko\MobileApi\Controllers\Search_Controller;
use Akuko\MobileApi\Controllers\Settings_Controller;
use Akuko\MobileApi\Controllers\Wishlist_Controller;
use Akuko\MobileApi\Middleware\Audit_Log_Middleware;
use Akuko\MobileApi\Middleware\Jwt_Auth_Middleware;
use Akuko\MobileApi\Middleware\Rate_Limit_Middleware;
use Akuko\MobileApi\Plugin;

defined( 'ABSPATH' ) || exit;

class Rest_Router {

	private const NAMESPACE = 'akuko/v1';

	public function __construct(
		private Container $container
	) {}

	public function register_routes(): void {
		$this->register_auth_routes();
		$this->register_book_routes();
		$this->register_category_routes();
		$this->register_author_routes();
		$this->register_search_routes();
		$this->register_library_routes();
		$this->register_reading_routes();
		$this->register_download_routes();
		$this->register_premium_routes();
		$this->register_payment_routes();
		$this->register_review_routes();
		$this->register_wishlist_routes();
		$this->register_notification_routes();
		$this->register_settings_routes();
		$this->register_ai_routes();
		$this->register_audiobook_routes();
		$this->register_recommendation_routes();
		$this->register_analytics_routes();
		$this->register_feature_flag_routes();

		add_filter( 'rest_post_dispatch', array( $this->get_audit(), 'log' ), 10, 3 );
	}

	private function get_audit(): Audit_Log_Middleware {
		return new Audit_Log_Middleware(
			Plugin::instance()->container()->get( \Akuko\MobileApi\Repositories\Interfaces\Analytics_Repository_Interface::class )
		);
	}

	private function controller( string $class ): object {
		return $this->resolve_controller( $class );
	}

	private function resolve_controller( string $class ): object {
		$container = Plugin::instance()->container();
		$jwt       = new Jwt_Auth_Middleware( $container->get( \Akuko\MobileApi\Services\Interfaces\AuthenticationService_Interface::class ) );
		$rate      = new Rate_Limit_Middleware();

		$map = array(
			Auth_Controller::class            => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\AuthenticationService_Interface::class ),
			Books_Controller::class           => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\BookService_Interface::class ),
			Authors_Controller::class         => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\AuthorService_Interface::class ),
			Search_Controller::class          => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\SearchService_Interface::class ),
			Library_Controller::class         => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\LibraryService_Interface::class ),
			Reading_Controller::class         => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\ReadingService_Interface::class ),
			Downloads_Controller::class       => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\DownloadService_Interface::class ),
			Premium_Controller::class         => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\PremiumService_Interface::class ),
			Payments_Controller::class        => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\PaymentService_Interface::class ),
			Reviews_Controller::class         => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\ReviewService_Interface::class ),
			Wishlist_Controller::class        => array( $jwt, $rate, \Akuko\MobileApi\Repositories\Interfaces\Wishlist_Repository_Interface::class ),
			Notifications_Controller::class     => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\NotificationService_Interface::class ),
			Settings_Controller::class        => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\SettingsService_Interface::class ),
			AI_Controller::class              => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\AIService_Interface::class ),
			Audiobooks_Controller::class      => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\AudiobookService_Interface::class ),
			Recommendations_Controller::class => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\RecommendationService_Interface::class ),
			Analytics_Controller::class       => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\AnalyticsService_Interface::class ),
			Feature_Flags_Controller::class   => array( $jwt, $rate, \Akuko\MobileApi\Services\Interfaces\FeatureFlagService_Interface::class ),
		);

		if ( ! isset( $map[ $class ] ) ) {
			throw new \RuntimeException( "Controller {$class} not mapped." );
		}

		$deps = $map[ $class ];
		$service = $container->get( $deps[2] );

		return new $class( $deps[0], $deps[1], $service );
	}

	private function route( string $route, array $args ): void {
		register_rest_route( self::NAMESPACE, $route, $args );
	}

	private function register_auth_routes(): void {
		$c = $this->controller( Auth_Controller::class );
		$this->route( '/auth/register', array( 'methods' => 'POST', 'callback' => array( $c, 'register' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/auth/login', array( 'methods' => 'POST', 'callback' => array( $c, 'login' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/auth/logout', array( 'methods' => 'POST', 'callback' => array( $c, 'logout' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/auth/forgot-password', array( 'methods' => 'POST', 'callback' => array( $c, 'forgot_password' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/auth/reset-password', array( 'methods' => 'POST', 'callback' => array( $c, 'reset_password' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/auth/refresh', array( 'methods' => 'POST', 'callback' => array( $c, 'refresh' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/auth/me', array( 'methods' => 'GET', 'callback' => array( $c, 'me' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_book_routes(): void {
		$c = $this->controller( Books_Controller::class );
		$this->route( '/books', array( 'methods' => 'GET', 'callback' => array( $c, 'index' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/books/featured', array( 'methods' => 'GET', 'callback' => array( $c, 'featured' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/books/trending', array( 'methods' => 'GET', 'callback' => array( $c, 'trending' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/books/new-releases', array( 'methods' => 'GET', 'callback' => array( $c, 'new_releases' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/books/(?P<id>\d+)', array( 'methods' => 'GET', 'callback' => array( $c, 'show' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/books/(?P<id>\d+)/related', array( 'methods' => 'GET', 'callback' => array( $c, 'related' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_category_routes(): void {
		$c = $this->controller( Books_Controller::class );
		$this->route( '/categories', array( 'methods' => 'GET', 'callback' => array( $c, 'categories' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_author_routes(): void {
		$c = $this->controller( Authors_Controller::class );
		$this->route( '/authors', array( 'methods' => 'GET', 'callback' => array( $c, 'index' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/authors/(?P<id>\d+)', array( 'methods' => 'GET', 'callback' => array( $c, 'show' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_search_routes(): void {
		$c = $this->controller( Search_Controller::class );
		$this->route( '/search', array( 'methods' => 'GET', 'callback' => array( $c, 'search' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_library_routes(): void {
		$c = $this->controller( Library_Controller::class );
		$this->route( '/library', array( 'methods' => 'GET', 'callback' => array( $c, 'index' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/library/continue-reading', array( 'methods' => 'GET', 'callback' => array( $c, 'continue_reading' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_reading_routes(): void {
		$c = $this->controller( Reading_Controller::class );
		$this->route( '/reading/progress/(?P<book_id>\d+)', array(
			array( 'methods' => 'GET', 'callback' => array( $c, 'get_progress' ), 'permission_callback' => '__return_true' ),
			array( 'methods' => 'PUT', 'callback' => array( $c, 'save_progress' ), 'permission_callback' => '__return_true' ),
		) );
		$this->route( '/bookmarks', array(
			array( 'methods' => 'GET', 'callback' => array( $c, 'bookmarks' ), 'permission_callback' => '__return_true' ),
			array( 'methods' => 'POST', 'callback' => array( $c, 'bookmarks' ), 'permission_callback' => '__return_true' ),
			array( 'methods' => 'DELETE', 'callback' => array( $c, 'bookmarks' ), 'permission_callback' => '__return_true' ),
		) );
		$this->route( '/highlights', array(
			array( 'methods' => 'GET', 'callback' => array( $c, 'highlights' ), 'permission_callback' => '__return_true' ),
			array( 'methods' => 'POST', 'callback' => array( $c, 'highlights' ), 'permission_callback' => '__return_true' ),
			array( 'methods' => 'DELETE', 'callback' => array( $c, 'highlights' ), 'permission_callback' => '__return_true' ),
		) );
		$this->route( '/notes', array(
			array( 'methods' => 'GET', 'callback' => array( $c, 'notes' ), 'permission_callback' => '__return_true' ),
			array( 'methods' => 'POST', 'callback' => array( $c, 'notes' ), 'permission_callback' => '__return_true' ),
			array( 'methods' => 'DELETE', 'callback' => array( $c, 'notes' ), 'permission_callback' => '__return_true' ),
		) );
	}

	private function register_download_routes(): void {
		$c = $this->controller( Downloads_Controller::class );
		$this->route( '/downloads/(?P<book_id>\d+)/request', array( 'methods' => 'POST', 'callback' => array( $c, 'request' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_premium_routes(): void {
		$c = $this->controller( Premium_Controller::class );
		$this->route( '/premium/status', array( 'methods' => 'GET', 'callback' => array( $c, 'status' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/premium/subscribe', array( 'methods' => 'POST', 'callback' => array( $c, 'subscribe' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_payment_routes(): void {
		$c = $this->controller( Payments_Controller::class );
		$this->route( '/payments/verify', array( 'methods' => 'POST', 'callback' => array( $c, 'verify' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/payments/history', array( 'methods' => 'GET', 'callback' => array( $c, 'history' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_review_routes(): void {
		$c = $this->controller( Reviews_Controller::class );
		$this->route( '/books/(?P<id>\d+)/reviews', array(
			array( 'methods' => 'GET', 'callback' => array( $c, 'index' ), 'permission_callback' => '__return_true' ),
			array( 'methods' => 'POST', 'callback' => array( $c, 'create' ), 'permission_callback' => '__return_true' ),
		) );
	}

	private function register_wishlist_routes(): void {
		$c = $this->controller( Wishlist_Controller::class );
		$this->route( '/wishlist', array(
			array( 'methods' => 'GET', 'callback' => array( $c, 'index' ), 'permission_callback' => '__return_true' ),
			array( 'methods' => 'POST', 'callback' => array( $c, 'add' ), 'permission_callback' => '__return_true' ),
			array( 'methods' => 'DELETE', 'callback' => array( $c, 'remove' ), 'permission_callback' => '__return_true' ),
		) );
	}

	private function register_notification_routes(): void {
		$c = $this->controller( Notifications_Controller::class );
		$this->route( '/notifications', array( 'methods' => 'GET', 'callback' => array( $c, 'index' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/notifications/device-token', array( 'methods' => 'POST', 'callback' => array( $c, 'device_token' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_settings_routes(): void {
		$c = $this->controller( Settings_Controller::class );
		$this->route( '/settings', array( 'methods' => 'GET', 'callback' => array( $c, 'index' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_ai_routes(): void {
		$c = $this->controller( AI_Controller::class );
		$this->route( '/ai/summary', array( 'methods' => 'POST', 'callback' => array( $c, 'summary' ), 'permission_callback' => '__return_true' ) );
		$this->route( '/ai/chat', array( 'methods' => 'POST', 'callback' => array( $c, 'chat' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_audiobook_routes(): void {
		$c = $this->controller( Audiobooks_Controller::class );
		$this->route( '/audiobooks/(?P<book_id>\d+)', array( 'methods' => 'GET', 'callback' => array( $c, 'show' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_recommendation_routes(): void {
		$c = $this->controller( Recommendations_Controller::class );
		$this->route( '/recommendations/home', array( 'methods' => 'GET', 'callback' => array( $c, 'home' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_analytics_routes(): void {
		$c = $this->controller( Analytics_Controller::class );
		$this->route( '/analytics/event', array( 'methods' => 'POST', 'callback' => array( $c, 'event' ), 'permission_callback' => '__return_true' ) );
	}

	private function register_feature_flag_routes(): void {
		$c = $this->controller( Feature_Flags_Controller::class );
		$this->route( '/feature-flags', array( 'methods' => 'GET', 'callback' => array( $c, 'index' ), 'permission_callback' => '__return_true' ) );
	}
}
