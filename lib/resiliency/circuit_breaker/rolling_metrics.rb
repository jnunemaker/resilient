require "resiliency/circuit_breaker/rolling_metrics/bucket"

module Resiliency
  class CircuitBreaker
    class RollingMetrics
      attr_reader :number_of_buckets
      attr_reader :bucket_size_in_seconds
      attr_reader :buckets

      def initialize(number_of_buckets:, bucket_size_in_seconds:)
        @number_of_buckets = number_of_buckets
        @bucket_size_in_seconds = bucket_size_in_seconds
        @buckets = []
        reset
      end

      def mark_success
        current_bucket.mark_success
      end

      def mark_failure
        current_bucket.mark_failure
      end

      def successes
        prune_buckets
        sum = 0
        @buckets.each { |bucket| sum += bucket.successes }
        sum
      end

      def failures
        prune_buckets
        sum = 0
        @buckets.each { |bucket| sum += bucket.failures }
        sum
      end

      def requests
        successes + failures
      end

      def error_percentage
        return 0 if failures == 0 || requests == 0
        ((failures / requests.to_f) * 100).to_i
      end

      def reset
        @buckets.clear
      end

      private

      def current_bucket
        timestamp = Time.now.to_i
        bucket = @buckets.detect { |bucket|
          timestamp >= bucket.start && timestamp < (bucket.start + @bucket_size_in_seconds )
        }
        return bucket if bucket

        bucket = Bucket.new(timestamp, timestamp + @bucket_size_in_seconds - 1)
        @buckets.push bucket

        prune_buckets(timestamp)
        bucket
      end

      def prune_buckets(timestamp = Time.now.to_i)
        cutoff = timestamp - (@number_of_buckets * @bucket_size_in_seconds)
        @buckets.delete_if { |bucket| bucket.finish <= cutoff }
      end
    end
  end
end
