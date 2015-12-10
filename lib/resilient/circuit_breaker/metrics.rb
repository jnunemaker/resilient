require "resilient/circuit_breaker/metrics/storage/memory"
require "resilient/circuit_breaker/metrics/bucket_range"
require "resilient/circuit_breaker/metrics/bucket_size"
require "resilient/circuit_breaker/metrics/window_size"

module Resilient
  class CircuitBreaker
    class Metrics
      attr_reader :window_size_in_seconds
      attr_reader :bucket_size_in_seconds
      attr_reader :buckets
      attr_reader :storage

      StorageSuccessKeys = [
        :successes,
      ].freeze

      StorageFailureKeys = [
        :failures,
      ].freeze

      StorageKeys = (StorageSuccessKeys + StorageFailureKeys).freeze

      def initialize(options = {})
        @window_size_in_seconds = options.fetch(:window_size_in_seconds, 60)
        @bucket_size_in_seconds = options.fetch(:bucket_size_in_seconds, 10)
        @window_size = WindowSize.new(@window_size_in_seconds)
        @bucket_size = BucketSize.new(@bucket_size_in_seconds)
        @storage = options.fetch(:storage) { Storage::Memory.new }
        @buckets = []
      end

      def success
        @storage.increment(current_bucket, StorageSuccessKeys)
        prune_buckets
        nil
      end

      def failure
        @storage.increment(current_bucket, StorageFailureKeys)
        prune_buckets
        nil
      end

      def successes
        prune_buckets
        @storage.sum(@buckets, :successes)[:successes]
      end

      def failures
        prune_buckets
        @storage.sum(@buckets, :failures)[:failures]
      end

      def requests
        prune_buckets
        requests = 0
        @storage.sum(@buckets, StorageKeys).each do |key, value|
          requests += value
        end
        requests
      end

      def error_percentage
        prune_buckets

        result = @storage.sum(@buckets, StorageKeys)
        successes = result[:successes]
        failures = result[:failures]

        requests = successes + failures
        return 0 if failures == 0 || requests == 0

        ((failures / requests.to_f) * 100).round
      end

      def reset
        @storage.prune(@buckets, StorageKeys)
        nil
      end

      private

      def current_bucket(timestamp = Time.now.to_i)
        bucket = @buckets.detect { |bucket| bucket.include?(timestamp) }
        return bucket if bucket

        bucket = @bucket_size.bucket(timestamp)
        @buckets.push bucket

        bucket
      end

      def prune_buckets(timestamp = Time.now.to_i)
        pruned_buckets = []
        bucket_range = BucketRange.generate(timestamp, @window_size, @bucket_size)

        @buckets.delete_if { |bucket|
          if bucket_range.prune?(bucket)
            pruned_buckets << bucket
            true
          end
        }

        if pruned_buckets.any?
          @storage.prune(pruned_buckets, StorageKeys)
        end
      end
    end
  end
end
