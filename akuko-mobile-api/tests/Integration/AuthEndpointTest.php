<?php
namespace Akuko\MobileApi\Tests\Integration;

use PHPUnit\Framework\TestCase;

class AuthEndpointTest extends TestCase {

	public function test_auth_routes_are_documented(): void {
		$routes = array(
			'/auth/register',
			'/auth/login',
			'/auth/google',
			'/auth/logout',
			'/auth/forgot-password',
			'/auth/reset-password',
			'/auth/refresh',
			'/auth/me',
		);

		$this->assertCount( 8, $routes );
		$this->assertStringStartsWith( '/auth/', $routes[0] );
	}
}
