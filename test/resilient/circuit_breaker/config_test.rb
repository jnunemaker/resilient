require "test_helper"
require "resilient/circuit_breaker/config"
require "resilient/instrumenters/noop"
require "resilient/instrumenters/memory"
require "resilient/test/config_interface"

module Resilient
  class CircuitBreaker
    class ConfigTest < Resilient::Test
      def setup
        @object = Config.new
      end

      include Test::ConfigInterface

      def test_defaults_force_open
        assert_equal false, @object.force_open
      end

      def test_allows_overriding_force_open
        assert_equal true, Config.new(force_open: true).force_open
      end

      def test_defaults_force_closed
        assert_equal false, @object.force_closed
      end

      def test_allows_overriding_force_closed
        assert_equal true, Config.new(force_closed: true).force_closed
      end

      def test_defaults_instrumenter
        assert_equal Instrumenters::Noop, @object.instrumenter
      end

      def test_allows_overriding_instrumenter
        instrumenter = Instrumenters::Memory.new
        assert_equal instrumenter, Config.new(instrumenter: instrumenter).instrumenter
      end

      def test_defaults_sleep_window_seconds
        assert_equal 5, @object.sleep_window_seconds
      end

      def test_allows_overriding_sleep_window_seconds
        assert_equal 2, Config.new(sleep_window_seconds: 2).sleep_window_seconds
      end

      def test_defaults_request_volume_threshold
        assert_equal 20, @object.request_volume_threshold
      end

      def test_allows_overriding_request_volume_threshold
        assert_equal 1, Config.new(request_volume_threshold: 1).request_volume_threshold
      end

      def test_defaults_error_threshold_percentage
        assert_equal 50, @object.error_threshold_percentage
      end

      def test_allows_overriding_error_threshold_percentage
        assert_equal 12, Config.new(error_threshold_percentage: 12).error_threshold_percentage
      end

      def test_defaults_number_of_buckets
        assert_equal 6, @object.number_of_buckets
      end

      def test_allows_overriding_number_of_buckets
        assert_equal 8, Config.new(number_of_buckets: 8).number_of_buckets
      end

      def test_defaults_bucket_size_in_seconds
        assert_equal 10, @object.bucket_size_in_seconds
      end

      def test_allows_overriding_bucket_size_in_seconds
        assert_equal 111, Config.new(bucket_size_in_seconds: 111).bucket_size_in_seconds
      end
    end
  end
end
