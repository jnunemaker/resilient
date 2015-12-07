module Resiliency
  class CircuitBreaker
    class RollingMetrics
      class Bucket
        attr_reader :start
        attr_reader :finish
        attr_reader :successes
        attr_reader :failures

        def initialize(start, finish)
          @start = start
          @finish = finish
          @successes = 0
          @failures = 0
        end

        def mark_success
          @successes += 1
        end

        def mark_failure
          @failures += 1
        end
      end
    end
  end
end
