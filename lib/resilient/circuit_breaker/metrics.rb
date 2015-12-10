require "resilient/circuit_breaker/metrics/storage/memory"

module Resilient
  class CircuitBreaker
    class Metrics
      attr_reader :number_of_buckets
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

      class Bucket
        attr_reader :timestamp_start
        attr_reader :timestamp_end

        def initialize(timestamp_start, timestamp_end)
          @timestamp_start = timestamp_start
          @timestamp_end = timestamp_end
        end

        def prune_before(number_of_buckets, bucket_size)
          @timestamp_end - (number_of_buckets * bucket_size.seconds)
        end

        def include?(timestamp)
          timestamp >= @timestamp_start && timestamp <= @timestamp_end
        end
      end

      class BucketRange
        def self.generate(timestamp, number_of_buckets, bucket_size)
          end_bucket = bucket_size.bucket(timestamp)
          start_bucket = bucket_size.bucket(end_bucket.prune_before(number_of_buckets, bucket_size))
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

      def initialize(options = {})
        @number_of_buckets = options.fetch(:number_of_buckets, 6)
        @bucket_size = BucketSize.new(options.fetch(:bucket_size_in_seconds, 10))
        @storage = options.fetch(:storage) { Storage::Memory.new }
        @buckets = []
      end

      def mark_success
        @storage.increment(current_bucket, StorageSuccessKeys)
        prune_buckets
        nil
      end

      def mark_failure
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
        @storage.reset(@buckets, StorageKeys)
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
        bucket_range = BucketRange.generate(timestamp, @number_of_buckets, @bucket_size)

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
