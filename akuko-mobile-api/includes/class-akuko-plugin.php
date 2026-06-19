<?php
/**
 * Main plugin bootstrap.
 *
 * @package Akuko\MobileApi
 */

namespace Akuko\MobileApi;

use Akuko\MobileApi\Admin\Admin_Menu;
use Akuko\MobileApi\Api\Rest_Router;
use Akuko\MobileApi\Cache\Cache_Invalidator;
use Akuko\MobileApi\Database\Migrations\Initial_Schema;
use Akuko\MobileApi\Events\Event_Dispatcher;
use Akuko\MobileApi\Events\WooCommerce_Listener;
use Akuko\MobileApi\Helpers\Google_Token_Verifier;
use Akuko\MobileApi\Helpers\Interfaces\Google_Token_Verifier_Interface;
use Akuko\MobileApi\Repositories\Analytics_Repository;
use Akuko\MobileApi\Repositories\Author_Repository;
use Akuko\MobileApi\Repositories\Book_Repository;
use Akuko\MobileApi\Repositories\Download_Repository;
use Akuko\MobileApi\Repositories\Interfaces\Analytics_Repository_Interface;
use Akuko\MobileApi\Repositories\Interfaces\Author_Repository_Interface;
use Akuko\MobileApi\Repositories\Interfaces\Book_Repository_Interface;
use Akuko\MobileApi\Repositories\Interfaces\Download_Repository_Interface;
use Akuko\MobileApi\Repositories\Interfaces\Payment_Repository_Interface;
use Akuko\MobileApi\Repositories\Interfaces\Publisher_Repository_Interface;
use Akuko\MobileApi\Repositories\Interfaces\Reading_Repository_Interface;
use Akuko\MobileApi\Repositories\Interfaces\Review_Repository_Interface;
use Akuko\MobileApi\Repositories\Interfaces\Subscription_Repository_Interface;
use Akuko\MobileApi\Repositories\Interfaces\User_Repository_Interface;
use Akuko\MobileApi\Repositories\Interfaces\Wishlist_Repository_Interface;
use Akuko\MobileApi\Repositories\Payment_Repository;
use Akuko\MobileApi\Repositories\Publisher_Repository;
use Akuko\MobileApi\Repositories\Reading_Repository;
use Akuko\MobileApi\Repositories\Review_Repository;
use Akuko\MobileApi\Repositories\Subscription_Repository;
use Akuko\MobileApi\Repositories\User_Repository;
use Akuko\MobileApi\Repositories\Wishlist_Repository;
use Akuko\MobileApi\Services\AIService;
use Akuko\MobileApi\Services\AnalyticsService;
use Akuko\MobileApi\Services\AudiobookService;
use Akuko\MobileApi\Services\AuthenticationService;
use Akuko\MobileApi\Services\AuthorService;
use Akuko\MobileApi\Services\BookService;
use Akuko\MobileApi\Services\CacheService;
use Akuko\MobileApi\Services\DownloadService;
use Akuko\MobileApi\Services\FeatureFlagService;
use Akuko\MobileApi\Services\Interfaces\AIService_Interface;
use Akuko\MobileApi\Services\Interfaces\AnalyticsService_Interface;
use Akuko\MobileApi\Services\Interfaces\AudiobookService_Interface;
use Akuko\MobileApi\Services\Interfaces\AuthenticationService_Interface;
use Akuko\MobileApi\Services\Interfaces\AuthorService_Interface;
use Akuko\MobileApi\Services\Interfaces\BookService_Interface;
use Akuko\MobileApi\Services\Interfaces\CacheService_Interface;
use Akuko\MobileApi\Services\Interfaces\DownloadService_Interface;
use Akuko\MobileApi\Services\Interfaces\FeatureFlagService_Interface;
use Akuko\MobileApi\Services\Interfaces\LibraryService_Interface;
use Akuko\MobileApi\Services\Interfaces\NotificationService_Interface;
use Akuko\MobileApi\Services\Interfaces\PaymentService_Interface;
use Akuko\MobileApi\Services\Interfaces\PremiumService_Interface;
use Akuko\MobileApi\Services\Interfaces\PublisherService_Interface;
use Akuko\MobileApi\Services\Interfaces\ReadingService_Interface;
use Akuko\MobileApi\Services\Interfaces\RecommendationService_Interface;
use Akuko\MobileApi\Services\Interfaces\ReviewService_Interface;
use Akuko\MobileApi\Services\Interfaces\SearchService_Interface;
use Akuko\MobileApi\Services\Interfaces\SettingsService_Interface;
use Akuko\MobileApi\Services\Interfaces\UserService_Interface;
use Akuko\MobileApi\Services\LibraryService;
use Akuko\MobileApi\Services\NotificationService;
use Akuko\MobileApi\Services\PaymentService;
use Akuko\MobileApi\Services\PremiumService;
use Akuko\MobileApi\Services\PublisherService;
use Akuko\MobileApi\Services\ReadingService;
use Akuko\MobileApi\Services\RecommendationService;
use Akuko\MobileApi\Services\ReviewService;
use Akuko\MobileApi\Services\SearchService;
use Akuko\MobileApi\Services\SettingsService;
use Akuko\MobileApi\Services\UserService;

defined( 'ABSPATH' ) || exit;

/**
 * Plugin singleton.
 */
final class Plugin {

	private static ?self $instance = null;

	private Container $container;

	private function __construct() {
		$this->container = new Container();
	}

	public static function instance(): self {
		if ( null === self::$instance ) {
			self::$instance = new self();
		}

		return self::$instance;
	}

	public function container(): Container {
		return $this->container;
	}

	public static function activate(): void {
		if ( ! class_exists( Initial_Schema::class ) ) {
			$migration = AKUKO_MOBILE_API_PATH . 'database/migrations/001_initial_schema.php';
			if ( is_readable( $migration ) ) {
				require_once $migration;
			}
		}

		Dependency_Checker::flag_if_missing();
		Initial_Schema::run();
		flush_rewrite_rules();
	}

	public static function deactivate(): void {
		flush_rewrite_rules();
	}

	public function boot(): void {
		$this->register_bindings();
		$this->register_hooks();

		load_plugin_textdomain( 'akuko-mobile-api', false, dirname( AKUKO_MOBILE_API_BASENAME ) . '/languages' );
	}

	private function register_bindings(): void {
		$c = $this->container;

		$c->singleton( Event_Dispatcher::class );

		$c->singleton( User_Repository_Interface::class, User_Repository::class );
		$c->singleton( Book_Repository_Interface::class, Book_Repository::class );
		$c->singleton( Author_Repository_Interface::class, Author_Repository::class );
		$c->singleton( Publisher_Repository_Interface::class, Publisher_Repository::class );
		$c->singleton( Subscription_Repository_Interface::class, Subscription_Repository::class );
		$c->singleton( Download_Repository_Interface::class, Download_Repository::class );
		$c->singleton( Payment_Repository_Interface::class, Payment_Repository::class );
		$c->singleton( Reading_Repository_Interface::class, Reading_Repository::class );
		$c->singleton( Review_Repository_Interface::class, Review_Repository::class );
		$c->singleton( Wishlist_Repository_Interface::class, Wishlist_Repository::class );
		$c->singleton( Analytics_Repository_Interface::class, Analytics_Repository::class );

		$c->singleton( CacheService_Interface::class, CacheService::class );
		$c->singleton( Google_Token_Verifier_Interface::class, Google_Token_Verifier::class );
		$c->singleton( AuthenticationService_Interface::class, AuthenticationService::class );
		$c->singleton( UserService_Interface::class, UserService::class );
		$c->singleton( BookService_Interface::class, BookService::class );
		$c->singleton( LibraryService_Interface::class, LibraryService::class );
		$c->singleton( ReadingService_Interface::class, ReadingService::class );
		$c->singleton( PremiumService_Interface::class, PremiumService::class );
		$c->singleton( PaymentService_Interface::class, PaymentService::class );
		$c->singleton( DownloadService_Interface::class, DownloadService::class );
		$c->singleton( RecommendationService_Interface::class, RecommendationService::class );
		$c->singleton( SearchService_Interface::class, SearchService::class );
		$c->singleton( ReviewService_Interface::class, ReviewService::class );
		$c->singleton( NotificationService_Interface::class, NotificationService::class );
		$c->singleton( AnalyticsService_Interface::class, AnalyticsService::class );
		$c->singleton( AuthorService_Interface::class, AuthorService::class );
		$c->singleton( PublisherService_Interface::class, PublisherService::class );
		$c->singleton( SettingsService_Interface::class, SettingsService::class );
		$c->singleton( FeatureFlagService_Interface::class, FeatureFlagService::class );
		$c->singleton( AIService_Interface::class, AIService::class );
		$c->singleton( AudiobookService_Interface::class, AudiobookService::class );

		$c->singleton( Rest_Router::class );
		$c->singleton( Admin_Menu::class );
		$c->singleton( Cache_Invalidator::class );
		$c->singleton( WooCommerce_Listener::class );
	}

	private function register_hooks(): void {
		add_action( 'rest_api_init', array( $this->container->get( Rest_Router::class ), 'register_routes' ) );

		if ( is_admin() ) {
			$this->container->get( Admin_Menu::class )->register();
		}

		$this->container->get( Cache_Invalidator::class )->register();
		$this->container->get( WooCommerce_Listener::class )->register();
	}
}
