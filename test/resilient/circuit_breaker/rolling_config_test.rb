require "test_helper"
require "resilient/circuit_breaker/rolling_config"

module Resilient
  class CircuitBreaker
    class RollingConfigTest < Minitest::Test
      def setup
        @object = RollingConfig.new
      end

      include RollingConfigInterfaceTest
    end
  end
end
