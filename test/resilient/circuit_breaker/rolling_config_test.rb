require "test_helper"
require "resilient/circuit_breaker/rolling_config"

module Resilient
  class CircuitBreaker
    class RollingConfigTest < Minitest::Test
      def setup
        @object = RollingConfig.new
      end

      include RollingConfigInterfaceTest

      def test_defaults_force_open
        assert_equal false, @object.force_open
      end

      def test_allows_overriding_force_open
        assert_equal true, RollingConfig.new(force_open: true).force_open
      end

      def test_defaults_force_closed
        assert_equal false, @object.force_closed
      end

      def test_allows_overriding_force_closed
        assert_equal true, RollingConfig.new(force_closed: true).force_closed
      end

      def test_defaults_sleep_window_seconds
        assert_equal 5, @object.sleep_window_seconds
      end

      def test_allows_overriding_sleep_window_seconds
        assert_equal 2, RollingConfig.new(sleep_window_seconds: 2).sleep_window_seconds
      end

      def test_defaults_request_volume_threshold
        assert_equal 20, @object.request_volume_threshold
      end

      def test_allows_overriding_request_volume_threshold
        assert_equal 1, RollingConfig.new(request_volume_threshold: 1).request_volume_threshold
      end

      def test_defaults_error_threshold_percentage
        assert_equal 50, @object.error_threshold_percentage
      end

      def test_allows_overriding_error_threshold_percentage
        assert_equal 12, RollingConfig.new(error_threshold_percentage: 12).error_threshold_percentage
      end

      def test_defaults_number_of_buckets
        assert_equal 6, @object.number_of_buckets
      end

      def test_allows_overriding_number_of_buckets
        assert_equal 8, RollingConfig.new(number_of_buckets: 8).number_of_buckets
      end

      def test_defaults_bucket_size_in_seconds
        assert_equal 10, @object.bucket_size_in_seconds
      end

      def test_allows_overriding_bucket_size_in_seconds
        assert_equal 111, RollingConfig.new(bucket_size_in_seconds: 111).bucket_size_in_seconds
      end
    end
  end
end
