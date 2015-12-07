require "test_helper"
require "resilient/circuit_breaker/metrics"

module Resilient
  class CircuitBreaker
    class MetricsTest < Minitest::Test
      def setup
        @object = Metrics.new
      end

      include MetricsInterfaceTest

      def test_error_percentage
        metrics = Metrics.new
        assert_equal 0, metrics.error_percentage
      end
    end
  end
end
