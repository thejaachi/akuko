<?php
namespace Akuko\MobileApi\Tests\Unit\Controllers;

use Akuko\MobileApi\Controllers\Auth_Controller;
use Akuko\MobileApi\Middleware\Jwt_Auth_Middleware;
use Akuko\MobileApi\Middleware\Rate_Limit_Middleware;
use Akuko\MobileApi\Services\Interfaces\AuthenticationService_Interface;
use PHPUnit\Framework\TestCase;

class AuthControllerTest extends TestCase {

	public function test_login_with_missing_credentials_returns_400(): void {
		$auth = $this->createMock( AuthenticationService_Interface::class );
		$auth->expects( $this->never() )->method( 'login' );

		$controller = new Auth_Controller(
			new Jwt_Auth_Middleware( $auth ),
			new Rate_Limit_Middleware(),
			$auth
		);
		$response = $controller->login( new \WP_REST_Request( array() ) );

		$this->assertInstanceOf( \WP_REST_Response::class, $response );
		$this->assertSame( 400, $response->status );
		$this->assertFalse( $response->data['success'] );
		$this->assertSame( 'invalid_data', $response->data['error']['code'] );
		$this->assertSame( 'Email and password are required.', $response->data['error']['message'] );
	}
}
