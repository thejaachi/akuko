<?php
/**
 * Simple dependency injection container.
 *
 * @package Akuko\MobileApi
 */

namespace Akuko\MobileApi;

defined( 'ABSPATH' ) || exit;

/**
 * Lightweight DI container with singleton and factory bindings.
 */
class Container {

	/**
	 * @var array<string, mixed>
	 */
	private array $bindings = array();

	/**
	 * @var array<string, object>
	 */
	private array $instances = array();

	/**
	 * Bind a factory or class name.
	 *
	 * @param string               $abstract Abstract identifier.
	 * @param callable|string|null $concrete Factory or class name.
	 */
	public function bind( string $abstract, callable|string|null $concrete = null ): void {
		$this->bindings[ $abstract ] = $concrete ?? $abstract;
	}

	/**
	 * Bind a singleton.
	 *
	 * @param string               $abstract Abstract identifier.
	 * @param callable|string|null $concrete Factory or class name.
	 */
	public function singleton( string $abstract, callable|string|null $concrete = null ): void {
		$this->bind(
			$abstract,
			function ( Container $container ) use ( $abstract, $concrete ) {
				if ( isset( $this->instances[ $abstract ] ) ) {
					return $this->instances[ $abstract ];
				}

				$resolved = $container->resolve( $concrete ?? $abstract );
				if ( is_object( $resolved ) ) {
					$this->instances[ $abstract ] = $resolved;
				}

				return $resolved;
			}
		);
	}

	/**
	 * Resolve from container.
	 *
	 * @param string $abstract Abstract identifier.
	 * @return mixed
	 */
	public function get( string $abstract ): mixed {
		if ( isset( $this->instances[ $abstract ] ) ) {
			return $this->instances[ $abstract ];
		}

		if ( ! isset( $this->bindings[ $abstract ] ) ) {
			return $this->resolve( $abstract );
		}

		$binding = $this->bindings[ $abstract ];

		if ( is_callable( $binding ) ) {
			return $binding( $this );
		}

		return $this->resolve( $binding );
	}

	/**
	 * Check if binding exists.
	 *
	 * @param string $abstract Abstract identifier.
	 */
	public function has( string $abstract ): bool {
		return isset( $this->bindings[ $abstract ] ) || class_exists( $abstract );
	}

	/**
	 * Instantiate a class with constructor injection.
	 *
	 * @param string $class Class name.
	 * @return mixed
	 */
	private function resolve( string $class ): mixed {
		if ( ! class_exists( $class ) ) {
			throw new \RuntimeException( sprintf( 'Class %s not found.', $class ) );
		}

		$reflector  = new \ReflectionClass( $class );
		$constructor = $reflector->getConstructor();

		if ( null === $constructor ) {
			return new $class();
		}

		$dependencies = array();

		foreach ( $constructor->getParameters() as $parameter ) {
			$type = $parameter->getType();

			if ( $type instanceof \ReflectionNamedType && ! $type->isBuiltin() ) {
				$dependencies[] = $this->get( $type->getName() );
				continue;
			}

			if ( $parameter->isDefaultValueAvailable() ) {
				$dependencies[] = $parameter->getDefaultValue();
				continue;
			}

			throw new \RuntimeException(
				sprintf( 'Cannot resolve parameter $%s for %s', $parameter->getName(), $class )
			);
		}

		return $reflector->newInstanceArgs( $dependencies );
	}
}
