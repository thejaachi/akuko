<?php
namespace Akuko\MobileApi\Tests\Unit\Helpers;

use Akuko\MobileApi\Helpers\Auth_Config;
use PHPUnit\Framework\TestCase;

class AuthConfigTest extends TestCase {

	public function test_skip_email_verification_defaults_to_true(): void {
		if ( defined( 'AKUKO_SKIP_EMAIL_VERIFICATION' ) ) {
			$this->markTestSkipped( 'AKUKO_SKIP_EMAIL_VERIFICATION is defined in this runtime.' );
		}

		$this->assertTrue( Auth_Config::skip_email_verification() );
	}

	public function test_google_client_ids_defaults_to_empty_array(): void {
		if ( defined( 'AKUKO_GOOGLE_CLIENT_ID' ) ) {
			$this->markTestSkipped( 'AKUKO_GOOGLE_CLIENT_ID is defined in this runtime.' );
		}

		$this->assertSame( array(), Auth_Config::google_client_ids() );
	}
}
