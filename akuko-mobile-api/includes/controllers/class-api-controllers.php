<?php
namespace Akuko\MobileApi\Controllers;

use Akuko\MobileApi\Helpers\Pagination;
use Akuko\MobileApi\Middleware\Jwt_Auth_Middleware;
use Akuko\MobileApi\Middleware\Rate_Limit_Middleware;
use Akuko\MobileApi\Services\Interfaces\AuthorService_Interface;
use Akuko\MobileApi\Services\Interfaces\LibraryService_Interface;
use Akuko\MobileApi\Services\Interfaces\ReadingService_Interface;
use Akuko\MobileApi\Services\Interfaces\SearchService_Interface;
use Akuko\MobileApi\Services\Interfaces\DownloadService_Interface;
use Akuko\MobileApi\Services\Interfaces\PremiumService_Interface;
use Akuko\MobileApi\Services\Interfaces\PaymentService_Interface;
use Akuko\MobileApi\Services\Interfaces\ReviewService_Interface;
use Akuko\MobileApi\Repositories\Interfaces\Wishlist_Repository_Interface;
use Akuko\MobileApi\Services\Interfaces\NotificationService_Interface;
use Akuko\MobileApi\Services\Interfaces\SettingsService_Interface;
use Akuko\MobileApi\Services\Interfaces\AIService_Interface;
use Akuko\MobileApi\Services\Interfaces\AudiobookService_Interface;
use Akuko\MobileApi\Services\Interfaces\RecommendationService_Interface;
use Akuko\MobileApi\Services\Interfaces\AnalyticsService_Interface;
use Akuko\MobileApi\Services\Interfaces\FeatureFlagService_Interface;

defined( 'ABSPATH' ) || exit;

class Authors_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private AuthorService_Interface $authors ) {
		parent::__construct( $jwt, $rl );
	}
	public function index( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$p = $this->pagination( $request );
		$r = $this->authors->list( array( 'limit' => $p['per_page'], 'offset' => $p['offset'] ) );
		return $this->success( $r['items'], Pagination::meta( $p['page'], $p['per_page'], $r['total'] ) );
	}
	public function show( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$a = $this->authors->get( (int) $request['id'] );
		return $a ? $this->success( $a ) : $this->error( __( 'Author not found.', 'akuko-mobile-api' ), 'not_found', 404 );
	}
}

class Search_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private SearchService_Interface $search ) {
		parent::__construct( $jwt, $rl );
	}
	public function search( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$q = sanitize_text_field( $request->get_param( 'q' ) ?? '' );
		if ( strlen( $q ) < 2 ) { return $this->error( __( 'Query too short.', 'akuko-mobile-api' ), 'invalid_query' ); }
		$p = $this->pagination( $request );
		$r = $this->search->search( $q, $p['per_page'], $p['offset'] );
		return $this->success( $r['items'], Pagination::meta( $p['page'], $p['per_page'], $r['total'] ) );
	}
}

class Library_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private LibraryService_Interface $library ) {
		parent::__construct( $jwt, $rl );
	}
	public function index( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$p = $this->pagination( $request );
		$r = $this->library->get_library( get_current_user_id(), $p['per_page'], $p['offset'] );
		return $this->success( $r['items'], Pagination::meta( $p['page'], $p['per_page'], $r['total'] ) );
	}
	public function continue_reading( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		return $this->success( $this->library->get_continue_reading( get_current_user_id(), (int) ( $request->get_param( 'limit' ) ?? 10 ) ) );
	}
}

class Reading_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private ReadingService_Interface $reading ) {
		parent::__construct( $jwt, $rl );
	}
	public function get_progress( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		return $this->success( $this->reading->get_progress( get_current_user_id(), (int) $request['book_id'] ) );
	}
	public function save_progress( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$ok = $this->reading->save_progress( get_current_user_id(), (int) $request['book_id'], (array) $request->get_json_params() );
		return $ok ? $this->success( array( 'saved' => true ) ) : $this->error( __( 'Could not save progress.', 'akuko-mobile-api' ) );
	}
	public function bookmarks( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		if ( 'POST' === $request->get_method() ) {
			$id = $this->reading->add_bookmark( get_current_user_id(), (int) $request->get_param( 'book_id' ), (array) $request->get_json_params() );
			return $this->success( array( 'id' => $id ), array(), 201 );
		}
		if ( 'DELETE' === $request->get_method() ) {
			$ok = $this->reading->delete_bookmark( get_current_user_id(), (int) $request->get_param( 'id' ) );
			return $ok ? $this->success( array( 'deleted' => true ) ) : $this->error( __( 'Bookmark not found.', 'akuko-mobile-api' ), 'not_found', 404 );
		}
		return $this->success( $this->reading->get_bookmarks( get_current_user_id(), $request->get_param( 'book_id' ) ? (int) $request->get_param( 'book_id' ) : null ) );
	}
	public function highlights( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		if ( 'POST' === $request->get_method() ) {
			$id = $this->reading->add_highlight( get_current_user_id(), (int) $request->get_param( 'book_id' ), (array) $request->get_json_params() );
			return $this->success( array( 'id' => $id ), array(), 201 );
		}
		if ( 'DELETE' === $request->get_method() ) {
			$ok = $this->reading->delete_highlight( get_current_user_id(), (int) $request->get_param( 'id' ) );
			return $ok ? $this->success( array( 'deleted' => true ) ) : $this->error( __( 'Highlight not found.', 'akuko-mobile-api' ), 'not_found', 404 );
		}
		return $this->success( $this->reading->get_highlights( get_current_user_id(), $request->get_param( 'book_id' ) ? (int) $request->get_param( 'book_id' ) : null ) );
	}
	public function notes( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		if ( 'POST' === $request->get_method() ) {
			$id = $this->reading->add_note( get_current_user_id(), (int) $request->get_param( 'book_id' ), (array) $request->get_json_params() );
			return $this->success( array( 'id' => $id ), array(), 201 );
		}
		if ( 'DELETE' === $request->get_method() ) {
			$ok = $this->reading->delete_note( get_current_user_id(), (int) $request->get_param( 'id' ) );
			return $ok ? $this->success( array( 'deleted' => true ) ) : $this->error( __( 'Note not found.', 'akuko-mobile-api' ), 'not_found', 404 );
		}
		return $this->success( $this->reading->get_notes( get_current_user_id(), $request->get_param( 'book_id' ) ? (int) $request->get_param( 'book_id' ) : null ) );
	}
}

class Downloads_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private DownloadService_Interface $downloads ) {
		parent::__construct( $jwt, $rl );
	}
	public function request( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$r = $this->downloads->request_download( get_current_user_id(), (int) $request['book_id'], sanitize_text_field( $request->get_param( 'format' ) ?? 'epub' ) );
		return is_wp_error( $r ) ? $this->from_wp_error( $r ) : $this->success( $r );
	}
}

class Premium_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private PremiumService_Interface $premium ) {
		parent::__construct( $jwt, $rl );
	}
	public function status( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		return $this->success( $this->premium->get_status( get_current_user_id() ) );
	}
	public function subscribe( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$r = $this->premium->subscribe( get_current_user_id(), sanitize_text_field( $request->get_param( 'reference' ) ) );
		return is_wp_error( $r ) ? $this->from_wp_error( $r ) : $this->success( $r );
	}
}

class Payments_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private PaymentService_Interface $payments ) {
		parent::__construct( $jwt, $rl );
	}
	public function verify( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$r = $this->payments->verify( get_current_user_id(), sanitize_text_field( $request->get_param( 'reference' ) ) );
		return is_wp_error( $r ) ? $this->from_wp_error( $r ) : $this->success( $r );
	}
	public function history( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$p = $this->pagination( $request );
		$items = $this->payments->get_history( get_current_user_id(), $p['per_page'], $p['offset'] );
		return $this->success( $items, Pagination::meta( $p['page'], $p['per_page'], count( $items ) ) );
	}
}

class Reviews_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private ReviewService_Interface $reviews ) {
		parent::__construct( $jwt, $rl );
	}
	public function index( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$p = $this->pagination( $request );
		$r = $this->reviews->list( (int) $request['id'], $p['per_page'], $p['offset'] );
		return $this->success( $r['items'], Pagination::meta( $p['page'], $p['per_page'], $r['total'] ) );
	}
	public function create( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$r = $this->reviews->create( (int) $request['id'], get_current_user_id(), (array) $request->get_json_params() );
		return is_wp_error( $r ) ? $this->from_wp_error( $r ) : $this->success( array( 'id' => $r ), array(), 201 );
	}
}

class Wishlist_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private Wishlist_Repository_Interface $wishlist ) {
		parent::__construct( $jwt, $rl );
	}
	public function index( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		return $this->success( $this->wishlist->get_items( get_current_user_id() ) );
	}
	public function add( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$this->wishlist->add( get_current_user_id(), (int) $request->get_param( 'book_id' ) );
		return $this->success( array( 'added' => true ), array(), 201 );
	}
	public function remove( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$this->wishlist->remove( get_current_user_id(), (int) $request->get_param( 'book_id' ) );
		return $this->success( array( 'removed' => true ) );
	}
}

class Notifications_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private NotificationService_Interface $notifications ) {
		parent::__construct( $jwt, $rl );
	}
	public function index( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$p = $this->pagination( $request );
		$r = $this->notifications->list( get_current_user_id(), $p['per_page'], $p['offset'] );
		return $this->success( $r['items'], Pagination::meta( $p['page'], $p['per_page'], $r['total'] ) );
	}
	public function device_token( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$ok = $this->notifications->register_device( get_current_user_id(), sanitize_text_field( $request->get_param( 'token' ) ), sanitize_text_field( $request->get_param( 'platform' ) ?? 'android' ) );
		return $ok ? $this->success( array( 'registered' => true ) ) : $this->error( __( 'Registration failed.', 'akuko-mobile-api' ) );
	}
}

class Settings_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private SettingsService_Interface $settings ) {
		parent::__construct( $jwt, $rl );
	}
	public function index( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		return $this->success( $this->settings->get_public_settings() );
	}
}

class AI_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private AIService_Interface $ai ) {
		parent::__construct( $jwt, $rl );
	}
	public function summary( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$r = $this->ai->summary( (int) $request->get_param( 'book_id' ), get_current_user_id() );
		return is_wp_error( $r ) ? $this->from_wp_error( $r ) : $this->success( $r );
	}
	public function chat( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$r = $this->ai->chat( get_current_user_id(), (array) $request->get_json_params() );
		return is_wp_error( $r ) ? $this->from_wp_error( $r ) : $this->success( $r );
	}
}

class Audiobooks_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private AudiobookService_Interface $audiobooks ) {
		parent::__construct( $jwt, $rl );
	}
	public function show( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->require_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$r = $this->audiobooks->get_for_book( (int) $request['book_id'], get_current_user_id() );
		return is_wp_error( $r ) ? $this->from_wp_error( $r ) : $this->success( $r );
	}
}

class Recommendations_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private RecommendationService_Interface $recommendations ) {
		parent::__construct( $jwt, $rl );
	}
	public function home( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		return $this->success( $this->recommendations->get_home( get_current_user_id() ) );
	}
}

class Analytics_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private AnalyticsService_Interface $analytics ) {
		parent::__construct( $jwt, $rl );
	}
	public function event( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		$params = (array) $request->get_json_params();
		$this->analytics->track_event( get_current_user_id(), sanitize_key( $params['event'] ?? 'unknown' ), $params['payload'] ?? array() );
		return $this->success( array( 'tracked' => true ) );
	}
}

class Feature_Flags_Controller extends Base_Controller {
	public function __construct( Jwt_Auth_Middleware $jwt, Rate_Limit_Middleware $rl, private FeatureFlagService_Interface $flags ) {
		parent::__construct( $jwt, $rl );
	}
	public function index( \WP_REST_Request $request ): \WP_REST_Response {
		$check = $this->optional_auth( $request );
		if ( is_wp_error( $check ) ) { return $this->from_wp_error( $check ); }
		return $this->success( $this->flags->get_all() );
	}
}
