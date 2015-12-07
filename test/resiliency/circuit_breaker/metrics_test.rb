require "test_helper"
require "resiliency/circuit_breaker/metrics"

module Resiliency
  class CircuitBreaker
    class MetricsTest < Minitest::Test
      def setup
        @object = Metrics.new
      end

      include MetricsInterfaceTest
    end
  end
end
