require "resilient/circuit_breaker/metrics/bucket"
require "resilient/circuit_breaker/metrics/storage/memory"

module Resilient
  class CircuitBreaker
    class Metrics
      attr_reader :number_of_buckets
      attr_reader :bucket_size_in_seconds
      attr_reader :buckets
      attr_reader :storage

      def initialize(options = {})
        @number_of_buckets = options.fetch(:number_of_buckets, 6)
        @bucket_size_in_seconds = options.fetch(:bucket_size_in_seconds, 10)
        @storage = options.fetch(:storage) { Storage::Memory.new }
        @buckets = []
      end

      def mark_success
        timestamp = Time.now.to_i
        bucket_start = timestamp / @bucket_size_in_seconds * @bucket_size_in_seconds
        bucket = bucket(bucket_start)
        @storage.increment(bucket, [:success])
        prune_buckets(timestamp)
        nil
      end

      def mark_failure
        timestamp = Time.now.to_i
        bucket_start = timestamp / @bucket_size_in_seconds * @bucket_size_in_seconds
        bucket = bucket(bucket_start)
        @storage.increment(bucket, [:failure])
        prune_buckets(timestamp)
        nil
      end

      def successes
        prune_buckets
        @storage.get(@buckets, :success).values.inject(0) { |sum, value|
          sum += value[:success]
        }
      end

      def failures
        prune_buckets
        @storage.get(@buckets, :failure).values.inject(0) { |sum, value|
          sum += value[:failure]
        }
      end

      def requests
        prune_buckets
        @storage.get(@buckets, [:success, :failure]).values.inject(0) { |sum, value|
          sum += value[:failure] + value[:success]
        }
      end

      def error_percentage
        prune_buckets
        successes = 0
        failures = 0
        @storage.get(@buckets, [:success, :failure]).values.each do |value|
          successes += value[:success]
          failures += value[:failure]
        end
        requests = successes + failures
        return 0 if failures == 0 || requests == 0
        ((failures / requests.to_f) * 100).round
      end

      def reset
        @storage.reset(@buckets, [:success, :failure])
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

        pruned_buckets = []
        @buckets.delete_if { |bucket|
          if cutoff_bucket_end >= bucket.timestamp_end
            pruned_buckets << bucket
            true
          end
        }
        if pruned_buckets.any?
          @storage.prune(pruned_buckets, [:success, :failure])
        end
      end
    end
  end
end
