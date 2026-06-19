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

	public function test_login_with_email_when_username_differs(): void {
		$user = $this->getMockBuilder( \WP_User::class )
			->disableOriginalConstructor()
			->onlyMethods( array() )
			->getMock();
		$user->ID        = 7;
		$user->user_pass = wp_hash_password( 'SecretPass123!' );

		$repo = $this->createMock( User_Repository_Interface::class );
		$repo->method( 'find_by_email' )->with( 'reader@example.com' )->willReturn( $user );
		$repo->expects( $this->once() )->method( 'store_refresh_token' );
		$repo->method( 'find' )->with( 7 )->willReturn( $user );

		$service = new AuthenticationService( $repo );
		$result  = $service->login( 'reader@example.com', 'SecretPass123!', null, null );

		$this->assertIsArray( $result );
		$this->assertArrayHasKey( 'access_token', $result );
	}

	public function test_login_rejects_wrong_password_for_email_lookup(): void {
		$user = $this->getMockBuilder( \WP_User::class )
			->disableOriginalConstructor()
			->onlyMethods( array() )
			->getMock();
		$user->ID        = 7;
		$user->user_pass = wp_hash_password( 'SecretPass123!' );

		$repo = $this->createMock( User_Repository_Interface::class );
		$repo->method( 'find_by_email' )->willReturn( $user );

		$service = new AuthenticationService( $repo );
		$result  = $service->login( 'reader@example.com', 'WrongPass123!', null, null );

		$this->assertInstanceOf( \WP_Error::class, $result );
		$this->assertSame( 'invalid_credentials', $result->get_error_code() );
	}

	public function test_oauth_google_returns_not_implemented(): void {
		$repo = $this->createMock( User_Repository_Interface::class );
		$service = new AuthenticationService( $repo );

		$result = $service->oauth_google( 'token' );

		$this->assertInstanceOf( \WP_Error::class, $result );
		$this->assertSame( 'not_implemented', $result->get_error_code() );
	}
}
