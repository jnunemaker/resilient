require "test_helper"
require "resilient/circuit_breaker/metrics"
require "resilient/test/metrics_interface"

module Resilient
  class CircuitBreaker
    class MetricsTest < Resilient::Test
      def setup
        @object = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)
      end

      include Test::MetricsInterface

      def test_success
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)
        metrics.success
        assert_equal 1, metrics.successes
      end

      def test_success_prunes
        now = Time.now
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)

        Timecop.freeze(now) do
          metrics.success
          assert_equal 1, metrics.buckets.length, debug_metrics(metrics)
        end

        Timecop.freeze(now + 1) do
          metrics.success
          assert_equal 2, metrics.buckets.length, debug_metrics(metrics)
        end

        Timecop.freeze(now + 4) do
          metrics.success
          assert_equal 3, metrics.buckets.length, debug_metrics(metrics)
        end

        Timecop.freeze(now + 10) do
          metrics.success
          assert_equal 1, metrics.buckets.length, debug_metrics(metrics)
        end
      end

      def test_success_prunes_with_greater_than_one_second_bucket_size
        now = Time.now
        metrics = Metrics.new(window_size_in_seconds: 60, bucket_size_in_seconds: 10)

        Timecop.freeze(now) do
          metrics.success
          assert_equal 1, metrics.buckets.length, debug_metrics(metrics)
        end

        Timecop.freeze(now + 10) do
          metrics.success
          assert_equal 2, metrics.buckets.length, debug_metrics(metrics)
        end

        Timecop.freeze(now + 40) do
          metrics.success
          assert_equal 3, metrics.buckets.length, debug_metrics(metrics)
        end

        Timecop.freeze(now + 100) do
          metrics.success
          assert_equal 1, metrics.buckets.length, debug_metrics(metrics)
        end
      end

      def test_failure
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)
        metrics.failure
        assert_equal 1, metrics.failures
      end

      def test_failure_prunes
        now = Time.now
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)

        Timecop.freeze(now) do
          metrics.failure
          assert_equal 1, metrics.buckets.length, debug_metrics(metrics)
        end

        Timecop.freeze(now + 1) do
          metrics.failure
          assert_equal 2, metrics.buckets.length, debug_metrics(metrics)
        end

        Timecop.freeze(now + 4) do
          metrics.failure
          assert_equal 3, metrics.buckets.length, debug_metrics(metrics)
        end

        Timecop.freeze(now + 9) do
          metrics.failure
          assert_equal 1, metrics.buckets.length, debug_metrics(metrics)
        end
      end

      def test_failure_prunes_with_greater_than_one_second_bucket_size
        now = Time.now
        metrics = Metrics.new(window_size_in_seconds: 60, bucket_size_in_seconds: 10)

        Timecop.freeze(now) do
          metrics.failure
          assert_equal 1, metrics.buckets.length, debug_metrics(metrics)
        end

        Timecop.freeze(now + 10) do
          metrics.failure
          assert_equal 2, metrics.buckets.length, debug_metrics(metrics)
        end

        Timecop.freeze(now + 40) do
          metrics.failure
          assert_equal 3, metrics.buckets.length, debug_metrics(metrics)
        end

        Timecop.freeze(now + 100) do
          metrics.failure
          assert_equal 1, metrics.buckets.length, debug_metrics(metrics)
        end
      end

      def test_successes
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)
        assert_equal 0, metrics.successes
      end

      def test_successes_is_pruned
        now = Time.now
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)

        Timecop.freeze(now) do
          metrics.success
          metrics.success
          metrics.success
          assert_equal 3, metrics.successes
        end

        Timecop.freeze(now + metrics.window_size_in_seconds) do
          assert_equal 0, metrics.successes
        end
      end

      def test_failures
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)
        assert_equal 0, metrics.failures
      end

      def test_failures_is_pruned
        now = Time.now
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)

        Timecop.freeze(now) do
          metrics.failure
          metrics.failure
          metrics.failure
          assert_equal 3, metrics.failures
        end

        Timecop.freeze(now + metrics.window_size_in_seconds) do
          assert_equal 0, metrics.failures
        end
      end

      def test_requests
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)
        assert_equal 0, metrics.requests
      end

      def test_requests_is_pruned
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)
        now = Time.now

        Timecop.freeze(now) do
          metrics.success
          metrics.success
          metrics.failure
          assert_equal 3, metrics.requests
        end

        Timecop.freeze(now + metrics.window_size_in_seconds) do
          assert_equal 0, metrics.requests
        end
      end

      def test_error_percentage_returns_zero_if_zero_requests
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)
        assert_equal 0, metrics.error_percentage
      end

      def test_error_percentage_returns_zero_if_zero_failures
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)
        metrics.success
        assert_equal 0, metrics.error_percentage
      end

      def test_error_percentage
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)
        metrics.success
        metrics.failure
        metrics.failure
        assert_equal 67, metrics.error_percentage
      end

      def test_error_percentage_is_pruned
        now = Time.now
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)

        Timecop.freeze(now) do
          metrics.success
          metrics.failure
          assert_equal 50, metrics.error_percentage
        end

        Timecop.freeze(now + metrics.window_size_in_seconds) do
          assert_equal 0, metrics.error_percentage
        end
      end

      def test_reset
        metrics = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)
        metrics.reset
        assert_equal 0, metrics.successes
        assert_equal 0, metrics.failures
      end
    end
  end
end
