require "test_helper"
require "resilient/circuit_breaker/registry"
require "resilient/test/circuit_breaker_registry_interface"

module Resilient
  class CircuitBreaker
    class RegistryTest < Test
      def setup
        super
        @object = Registry.new
      end

      include Test::CircuitBreakerRegistryInterface

      def test_default_class_accessors
        original_default = Registry.default
        assert_instance_of Registry, Registry.default
        Registry.default = @object
        assert_equal @object, Registry.default
      ensure
        Registry.default = original_default
      end

      def test_class_reset
        Registry.default.fetch("foo") { "bar" }
        Registry.reset
        assert_equal "reset!", Registry.default.fetch("foo") { "reset!" }
      end
    end
  end
end
