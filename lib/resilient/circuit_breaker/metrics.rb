module Resiliency
  class CircuitBreaker
    class Metrics
      attr_reader :successes
      attr_reader :failures

      def initialize
        reset
      end

      def mark_success
        @successes += 1
        nil
      end

      def mark_failure
        @failures += 1
        nil
      end

      def requests
        @failures + @successes
      end

      def error_percentage
        return 0 if @failures == 0 || requests == 0
        ((@failures / requests.to_f) * 100).to_i
      end

      def reset
        @failures = 0
        @successes = 0
        nil
      end
    end
  end
end
