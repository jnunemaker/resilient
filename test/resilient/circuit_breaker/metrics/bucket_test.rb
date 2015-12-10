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

        def test_bucket_size_in_seconds
          bucket = Bucket.new(10, 19)
          assert_equal 10, bucket.size_in_seconds # 0 and 1 both count
        end

        def test_include_for_timestamp_in_bucket
          bucket = Bucket.new(10, 19)
          (10..19).each do |n|
            assert bucket.include?(n),
              "#{n} was expected to be included in bucket but was not"
          end
        end

        def test_include_for_timestamp_older_than_bucket
          bucket = Bucket.new(10, 19)
          refute bucket.include?(9)
        end

        def test_include_for_timestamp_newer_than_bucket
          bucket = Bucket.new(10, 19)
          refute bucket.include?(20)
        end
      end
    end
  end
end
