module Resilient
  class CircuitBreaker
    class Metrics
      class Bucket
        attr_reader :timestamp_start
        attr_reader :timestamp_end
        attr_reader :successes
        attr_reader :failures

        def initialize(timestamp_start, timestamp_end)
          @timestamp_start = timestamp_start
          @timestamp_end = timestamp_end
          @successes = 0
          @failures = 0
        end

        def size_in_seconds
          # inclusive of start second so we add 1
          @timestamp_end - @timestamp_start + 1
        end

        def include?(timestamp)
          timestamp >= @timestamp_start && timestamp <= @timestamp_end
        end
      end
    end
  end
end
