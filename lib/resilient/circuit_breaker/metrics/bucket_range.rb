module Resilient
  class CircuitBreaker
    class Metrics
      class BucketRange
        def self.generate(timestamp, window_size, bucket_size)
          end_bucket = bucket_size.bucket(timestamp)
          start_bucket = bucket_size.bucket(end_bucket.prune_before(window_size))
          bucket_range = new(start_bucket, end_bucket)
        end

        attr_reader :start_bucket
        attr_reader :end_bucket

        def initialize(start_bucket, end_bucket)
          @start_bucket = start_bucket
          @end_bucket = end_bucket
        end

        def prune?(bucket)
          bucket.timestamp_end <= @start_bucket.timestamp_end
        end
      end
    end
  end
end
