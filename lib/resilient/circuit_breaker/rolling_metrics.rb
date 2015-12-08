require "resilient/circuit_breaker/rolling_metrics/bucket"

module Resilient
  class CircuitBreaker
    class RollingMetrics
      attr_reader :number_of_buckets
      attr_reader :bucket_size_in_seconds
      attr_reader :buckets

      def initialize(options = {})
        @number_of_buckets = options.fetch(:number_of_buckets, 6)
        @bucket_size_in_seconds = options.fetch(:bucket_size_in_seconds, 10)
        reset
      end

      def mark_success
        timestamp = Time.now.to_i
        bucket_start = timestamp / @bucket_size_in_seconds * @bucket_size_in_seconds
        bucket(bucket_start).mark_success
        prune_buckets(timestamp)
        nil
      end

      def mark_failure
        timestamp = Time.now.to_i
        bucket_start = timestamp / @bucket_size_in_seconds * @bucket_size_in_seconds
        bucket(bucket_start).mark_failure
        prune_buckets(timestamp)
        nil
      end

      def successes
        prune_buckets
        @buckets.inject(0) { |sum, bucket| sum += bucket.successes }
      end

      def failures
        prune_buckets
        @buckets.inject(0) { |sum, bucket| sum += bucket.failures }
      end

      def requests
        prune_buckets
        @buckets.inject(0) { |sum, bucket| sum += bucket.requests }
      end

      def error_percentage
        return 0 if failures == 0 || requests == 0
        ((failures / requests.to_f) * 100).round
      end

      def reset
        @buckets = []
        nil
      end

      private

      def bucket(timestamp)
        bucket = @buckets.detect { |bucket| bucket.include?(timestamp) }
        return bucket if bucket

        bucket = Bucket.new(timestamp, timestamp + @bucket_size_in_seconds - 1)
        @buckets.push bucket

        bucket
      end

      def prune_buckets(timestamp = Time.now.to_i)
        bucket_start = timestamp / @bucket_size_in_seconds * @bucket_size_in_seconds
        bucket_end = bucket_start + @bucket_size_in_seconds - 1
        cutoff_bucket_end = bucket_end - (@number_of_buckets * @bucket_size_in_seconds)

        @buckets.delete_if { |bucket|
          cutoff_bucket_end >= bucket.timestamp_end
        }
      end
    end
  end
end
