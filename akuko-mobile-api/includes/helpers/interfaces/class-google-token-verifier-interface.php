<?php
namespace Akuko\MobileApi\Helpers\Interfaces;

defined( 'ABSPATH' ) || exit;

interface Google_Token_Verifier_Interface {

	/**
	 * Verify a Google ID token and return normalized claims.
	 *
	 * @return array{email:string,given_name?:string,family_name?:string,name?:string,sub:string}|\WP_Error
	 */
	public function verify( string $id_token ): array|\WP_Error;
}
