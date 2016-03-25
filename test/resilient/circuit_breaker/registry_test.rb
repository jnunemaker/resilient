require "test_helper"
require "resilient/circuit_breaker/registry"
require "resilient/test/circuit_breaker_registry_interface"

module Resilient
  class CircuitBreaker
    class RegistryTest < Resilient::Test
      def setup
        super
        @object = Registry.new
      end

      include Test::CircuitBreakerRegistryInterface
    end
  end
end
