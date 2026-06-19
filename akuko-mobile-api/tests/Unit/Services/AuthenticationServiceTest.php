<?php
namespace Akuko\MobileApi\Tests\Unit\Services;

use Akuko\MobileApi\Helpers\Interfaces\Google_Token_Verifier_Interface;
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

	public function test_oauth_google_issues_tokens_for_existing_user(): void {
		$user = $this->getMockBuilder( \WP_User::class )
			->disableOriginalConstructor()
			->onlyMethods( array() )
			->getMock();
		$user->ID = 9;

		$repo = $this->createMock( User_Repository_Interface::class );
		$repo->method( 'find_by_email' )->with( 'reader@gmail.com' )->willReturn( $user );
		$repo->expects( $this->once() )->method( 'store_refresh_token' );
		$repo->method( 'find' )->with( 9 )->willReturn( $user );

		$verifier = $this->createMock( Google_Token_Verifier_Interface::class );
		$verifier->method( 'verify' )->with( 'google-id-token' )->willReturn(
			array(
				'email'       => 'reader@gmail.com',
				'given_name'  => 'Ada',
				'family_name' => 'Lovelace',
				'name'        => 'Ada Lovelace',
				'sub'         => 'google-subject-123',
			)
		);

		$service = new AuthenticationService( $repo, $verifier );
		$result  = $service->oauth_google( 'google-id-token', 'device-1', 'Pixel' );

		$this->assertIsArray( $result );
		$this->assertArrayHasKey( 'access_token', $result );
		$this->assertArrayHasKey( 'refresh_token', $result );
	}

	public function test_oauth_google_creates_user_when_missing(): void {
		$user = $this->getMockBuilder( \WP_User::class )
			->disableOriginalConstructor()
			->onlyMethods( array() )
			->getMock();
		$user->ID = 11;

		$repo = $this->createMock( User_Repository_Interface::class );
		$repo->method( 'find_by_email' )->with( 'new@gmail.com' )->willReturn( null );
		$repo->expects( $this->once() )->method( 'create' )->with(
			$this->callback(
				function ( array $data ): bool {
					return 'new@gmail.com' === $data['email']
						&& ! empty( $data['password'] )
						&& 'Grace' === $data['first_name']
						&& 'Hopper' === $data['last_name'];
				}
			)
		)->willReturn( 11 );
		$repo->expects( $this->once() )->method( 'store_refresh_token' );
		$repo->method( 'find' )->with( 11 )->willReturn( $user );

		$verifier = $this->createMock( Google_Token_Verifier_Interface::class );
		$verifier->method( 'verify' )->willReturn(
			array(
				'email'       => 'new@gmail.com',
				'given_name'  => 'Grace',
				'family_name' => 'Hopper',
				'name'        => 'Grace Hopper',
				'sub'         => 'google-subject-456',
			)
		);

		$service = new AuthenticationService( $repo, $verifier );
		$result  = $service->oauth_google( 'google-id-token' );

		$this->assertIsArray( $result );
		$this->assertArrayHasKey( 'access_token', $result );
	}

	public function test_oauth_google_returns_verifier_error(): void {
		$repo = $this->createMock( User_Repository_Interface::class );
		$verifier = $this->createMock( Google_Token_Verifier_Interface::class );
		$verifier->method( 'verify' )->willReturn(
			new \WP_Error( 'invalid_token', 'Invalid Google ID token.', array( 'status' => 401 ) )
		);

		$service = new AuthenticationService( $repo, $verifier );
		$result  = $service->oauth_google( 'bad-token' );

		$this->assertInstanceOf( \WP_Error::class, $result );
		$this->assertSame( 'invalid_token', $result->get_error_code() );
	}
}
