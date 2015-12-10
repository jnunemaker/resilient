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
        @bucket_size_in_seconds = options.fetch(:bucket_size_in_seconds, 10)
        @bucket_size = BucketSize.new(@bucket_size_in_seconds)
        @storage = options.fetch(:storage) { Storage::Memory.new }
        @buckets = []
      end

      def mark_success
        timestamp = Time.now.to_i
        bucket_start = @bucket_size.aligned_start(timestamp)
        bucket = bucket(bucket_start)
        @storage.increment(bucket, StorageSuccessKeys)
        prune_buckets(timestamp)
        nil
      end

      def mark_failure
        timestamp = Time.now.to_i
        bucket_start = @bucket_size.aligned_start(timestamp)
        bucket = bucket(bucket_start)
        @storage.increment(bucket, StorageFailureKeys)
        prune_buckets(timestamp)
        nil
      end

      def successes
        prune_buckets

        @storage.get(@buckets, :successes).values.inject(0) { |sum, value|
          sum += value[:successes]
        }
      end

      def failures
        prune_buckets

        @storage.get(@buckets, :failures).values.inject(0) { |sum, value|
          sum += value[:failures]
        }
      end

      def requests
        prune_buckets

        @storage.get(@buckets, StorageKeys).values.inject(0) { |sum, value|
          sum += value[:failures] + value[:successes]
        }
      end

      def error_percentage
        prune_buckets
        successes = 0
        failures = 0

        @storage.get(@buckets, StorageKeys).values.each do |value|
          successes += value[:successes]
          failures += value[:failures]
        end

        requests = successes + failures
        return 0 if failures == 0 || requests == 0

        ((failures / requests.to_f) * 100).round
      end

      def reset
        @storage.reset(@buckets, StorageKeys)
        nil
      end

      private

      def bucket(timestamp)
        bucket = @buckets.detect { |bucket| bucket.include?(timestamp) }
        return bucket if bucket

        bucket = @bucket_size.bucket(timestamp)
        @buckets.push bucket

        bucket
      end

      def prune_buckets(timestamp = Time.now.to_i)
        pruned_buckets = []
        bucket = @bucket_size.bucket(timestamp)
        prune_buckets_ending_before = bucket.prune_before(@number_of_buckets, @bucket_size)

        @buckets.delete_if { |bucket|
          if bucket.timestamp_end <= prune_buckets_ending_before
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
