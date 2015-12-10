module Resilient
  class CircuitBreaker
    class Metrics
      class Bucket
        attr_reader :timestamp_start
        attr_reader :timestamp_end

        def initialize(timestamp_start, timestamp_end)
          @timestamp_start = timestamp_start
          @timestamp_end = timestamp_end
        end

        def prune_before(window_size)
          @timestamp_end - window_size.seconds
        end

        def include?(timestamp)
          timestamp >= @timestamp_start && timestamp <= @timestamp_end
        end
      end
    end
  end
end
