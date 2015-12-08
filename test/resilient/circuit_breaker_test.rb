require "test_helper"
require "resilient/circuit_breaker"

module Resilient
  class CircuitBreakerTest < Resilient::Test
    def setup
      @object = CircuitBreaker.new
    end

    include CircuitBreakerInterfaceTest

    def test_allow_request_when_under_error_threshold_percentage
      config = CircuitBreaker::RollingConfig.new(default_test_config_options({
        error_threshold_percentage: 51,
      }))
      circuit_breaker = CircuitBreaker.new(config: config)
      circuit_breaker.mark_success
      circuit_breaker.mark_failure

      assert circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_allow_request_when_over_error_threshold_percentage
      config = CircuitBreaker::RollingConfig.new(default_test_config_options({
        error_threshold_percentage: 49,
      }))
      circuit_breaker = CircuitBreaker.new(config: config)
      circuit_breaker.mark_success
      circuit_breaker.mark_failure

      refute circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_allow_request_when_at_error_threshold_percentage
      config = CircuitBreaker::RollingConfig.new(default_test_config_options({
        error_threshold_percentage: 50,
      }))
      circuit_breaker = CircuitBreaker.new(config: config)
      circuit_breaker.mark_success
      circuit_breaker.mark_failure

      refute circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_allow_request_when_under_request_volume_threshold
      config = CircuitBreaker::RollingConfig.new(default_test_config_options({
        request_volume_threshold: 5,
      }))
      circuit_breaker = CircuitBreaker.new(config: config)
      4.times { circuit_breaker.metrics.mark_failure }

      assert circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_allow_request_with_circuit_open_but_after_sleep_window_seconds
      now = Time.now
      config = CircuitBreaker::RollingConfig.new(default_test_config_options({
        error_threshold_percentage: 49,
        sleep_window_seconds: 5,
      }))
      circuit_breaker = CircuitBreaker.new(config: config)
      circuit_breaker.mark_success
      circuit_breaker.mark_failure

      assert_equal 0, circuit_breaker.opened_or_last_checked_at_epoch

      Timecop.freeze(now) do
        refute circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)
        assert_equal now.to_i, circuit_breaker.opened_or_last_checked_at_epoch
      end

      Timecop.freeze(now + config.sleep_window_seconds - 1) do
        refute circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)
        assert_equal now.to_i, circuit_breaker.opened_or_last_checked_at_epoch
      end

      Timecop.freeze(now + config.sleep_window_seconds) do
        refute circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)
        assert_equal now.to_i, circuit_breaker.opened_or_last_checked_at_epoch
      end

      Timecop.freeze(now + config.sleep_window_seconds + 1) do
        assert circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)

        assert_equal (now + config.sleep_window_seconds + 1).to_i,
          circuit_breaker.opened_or_last_checked_at_epoch
      end
    end

    def test_allow_request_when_forced_open_but_under_threshold
      config = CircuitBreaker::RollingConfig.new(default_test_config_options({
        error_threshold_percentage: 51,
        force_open: true,
      }))
      circuit_breaker = CircuitBreaker.new(config: config)
      circuit_breaker.mark_success
      circuit_breaker.mark_failure

      refute circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_allow_request_when_forced_closed_but_over_threshold
      config = CircuitBreaker::RollingConfig.new(default_test_config_options({
        error_threshold_percentage: 49,
        request_volume_threshold: 0,
        force_closed: true,
      }))
      circuit_breaker = CircuitBreaker.new(config: config)
      circuit_breaker.mark_success
      circuit_breaker.mark_failure

      assert circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_mark_success_when_open_does_reset_metrics
      metrics = Minitest::Mock.new
      circuit_breaker = CircuitBreaker.new(open: true, metrics: metrics)

      metrics.expect :reset, nil
      circuit_breaker.mark_success
      metrics.verify
    end

    def test_mark_success_when_not_open_calls_mark_success_on_metrics
      metrics = Minitest::Mock.new
      circuit_breaker = CircuitBreaker.new(open: false, metrics: metrics)

      metrics.expect :mark_success, nil
      circuit_breaker.mark_success
      metrics.verify
    end

    def test_mark_failure_calls_mark_failure_on_metrics
      metrics = Minitest::Mock.new
      circuit_breaker = CircuitBreaker.new(metrics: metrics)

      metrics.expect :mark_failure, nil
      circuit_breaker.mark_failure
      metrics.verify
    end

    def test_reset_calls_reset_on_metrics
      metrics = Minitest::Mock.new
      circuit_breaker = CircuitBreaker.new(metrics: metrics)

      metrics.expect :reset, nil
      circuit_breaker.reset
      metrics.verify
    end

    def test_reset_sets_open_to_false
      circuit_breaker = CircuitBreaker.new
      circuit_breaker.reset

      assert_equal false, circuit_breaker.open
    end

    def test_reset_sets_opened_or_last_checked_at_epoch_to_zero
      circuit_breaker = CircuitBreaker.new
      circuit_breaker.reset

      assert_equal 0, circuit_breaker.opened_or_last_checked_at_epoch
    end

    private

    # Returns a Hash of default config options set in a way that all the short
    # circuit config options are turned off.
    def default_test_config_options(options = {})
      {
        request_volume_threshold: 0,
        force_closed: false,
        force_open: false,
      }.merge(options)
    end
  end
end
