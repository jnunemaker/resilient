require "test_helper"
require "resilient/circuit_breaker/metrics"
require "resilient/test/metrics_interface"

module Resilient
  class CircuitBreaker
    class MetricsTest < Test
      def setup
        super
        @object = Metrics.new(window_size_in_seconds: 5, bucket_size_in_seconds: 1)
      end

      include Test::MetricsInterface

      def test_success
        @object.success
        assert_successes @object, 1
      end

      def test_success_prunes
        now = Time.now

        Timecop.freeze(now) do
          @object.success
          assert_equal 1, @object.buckets.length, debug_metrics(@object)
        end

        Timecop.freeze(now + 1) do
          @object.success
          assert_equal 2, @object.buckets.length, debug_metrics(@object)
        end

        Timecop.freeze(now + 4) do
          @object.success
          assert_equal 3, @object.buckets.length, debug_metrics(@object)
        end

        Timecop.freeze(now + 10) do
          @object.success
          assert_equal 1, @object.buckets.length, debug_metrics(@object)
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
        @object.failure
        assert_failures @object, 1
      end

      def test_failure_prunes
        now = Time.now

        Timecop.freeze(now) do
          @object.failure
          assert_equal 1, @object.buckets.length, debug_metrics(@object)
        end

        Timecop.freeze(now + 1) do
          @object.failure
          assert_equal 2, @object.buckets.length, debug_metrics(@object)
        end

        Timecop.freeze(now + 4) do
          @object.failure
          assert_equal 3, @object.buckets.length, debug_metrics(@object)
        end

        Timecop.freeze(now + 9) do
          @object.failure
          assert_equal 1, @object.buckets.length, debug_metrics(@object)
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

      def test_under_request_volume_threshold
        assert @object.under_request_volume_threshold?(1)
        refute @object.under_request_volume_threshold?(0)
        10.times { @object.success }
        assert @object.under_request_volume_threshold?(11)
        refute @object.under_request_volume_threshold?(10)
        refute @object.under_request_volume_threshold?(9)
      end

      def test_under_request_volume_threshold_is_pruned
        now = Time.now
        Timecop.freeze(now) do
          @object.success
          @object.success
          @object.success
          assert_successes @object, 3
        end

        Timecop.freeze(now + @object.window_size_in_seconds) do
          @object.under_request_volume_threshold?(1)
          assert_successes @object, 0
        end
      end

      def test_under_error_threshold_percentage
        @object.success
        @object.failure
        @object.failure
        assert @object.under_error_threshold_percentage?(68)
        assert @object.under_error_threshold_percentage?(67)
        refute @object.under_error_threshold_percentage?(66)
      end

      def test_under_error_threshold_percentage_with_zero_requests
        assert @object.under_error_threshold_percentage?(10)
      end

      def test_under_error_threshold_percentage_with_zero_failures
        @object.success
        assert @object.under_error_threshold_percentage?(10)
      end

      def test_under_error_threshold_percentage_is_pruned
        now = Time.now
        Timecop.freeze(now) do
          @object.success
          @object.success
          @object.success
          assert_successes @object, 3
        end

        Timecop.freeze(now + @object.window_size_in_seconds) do
          @object.under_error_threshold_percentage?(1)
          assert_successes @object, 0
        end
      end

      def test_reset
        @object.success
        @object.failure
        assert_successes @object, 1
        assert_failures @object, 1

        @object.reset

        assert_successes @object, 0
        assert_failures @object, 0
      end

      private

      def assert_successes(metrics, expected_successes)
        actual_successes = metrics.storage.sum(metrics.buckets, Metrics::StorageSuccessKeys)[Metrics::StorageSuccessKeys.first]
        assert_equal expected_successes, actual_successes
      end

      def assert_failures(metrics, expected_failures)
        actual_failures = metrics.storage.sum(metrics.buckets, Metrics::StorageFailureKeys)[Metrics::StorageFailureKeys.first]
        assert_equal expected_failures, actual_failures
      end
    end
  end
end
