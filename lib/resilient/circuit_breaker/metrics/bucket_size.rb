require "resilient/circuit_breaker/metrics/bucket"

module Resilient
  class CircuitBreaker
    class Metrics
      class BucketSize
        attr_reader :seconds

        def initialize(seconds)
          @seconds = seconds
        end

        def aligned_start(timestamp = Time.now.to_i)
          timestamp / @seconds * @seconds
        end

        def aligned_end(timestamp = Time.now.to_i)
          aligned_start(timestamp) + @seconds - 1
        end

        def bucket(timestamp = Time.now.to_i)
          Bucket.new aligned_start(timestamp), aligned_end(timestamp)
        end
      end
    end
  end
end
