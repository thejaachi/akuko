<?php
namespace Akuko\MobileApi\Tests\Unit\Services;

use Akuko\MobileApi\Repositories\Interfaces\User_Repository_Interface;
use Akuko\MobileApi\Services\AuthenticationService;
use PHPUnit\Framework\TestCase;

class AuthenticationServiceTest extends TestCase {

	public function test_register_requires_email_and_password(): void {
		$repo = $this->createMock( User_Repository_Interface::class );
		$service = new AuthenticationService( $repo );

		$result = $service->register( array() );

		$this->assertInstanceOf( \WP_Error::class, $result );
		$this->assertSame( 'invalid_data', $result->get_error_code() );
	}

	public function test_oauth_google_returns_not_implemented(): void {
		$repo = $this->createMock( User_Repository_Interface::class );
		$service = new AuthenticationService( $repo );

		$result = $service->oauth_google( 'token' );

		$this->assertInstanceOf( \WP_Error::class, $result );
		$this->assertSame( 'not_implemented', $result->get_error_code() );
	}
}
