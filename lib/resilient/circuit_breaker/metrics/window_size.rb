require "resilient/circuit_breaker/metrics/bucket"

module Resilient
  class CircuitBreaker
    class Metrics
      class WindowSize
        attr_reader :seconds

        def initialize(seconds)
          @seconds = seconds
        end
      end
    end
  end
end
