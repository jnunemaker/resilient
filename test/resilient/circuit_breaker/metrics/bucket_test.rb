require "test_helper"
require "resilient/circuit_breaker/config"

module Resilient
  class CircuitBreaker
    class Metrics
      class BucketTest < Resilient::Test
        def test_initialize
          bucket = Bucket.new(0, 1)
          assert_equal 0, bucket.timestamp_start
          assert_equal 1, bucket.timestamp_end
        end
      end
    end
  end
end
