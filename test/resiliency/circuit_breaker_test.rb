require "test_helper"
require "resiliency/circuit_breaker"

module Resiliency
  class CircuitBreakerTest < Minitest::Test
    def test_allow_request_when_under_threshold
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 51,
        request_volume_threshold: 2,
      })
      metrics = CircuitBreaker::Metrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      assert circuit_breaker.allow_request?
    end

    def test_allow_request_when_over_threshold
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 49,
        request_volume_threshold: 2,
      })
      metrics = CircuitBreaker::Metrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      refute circuit_breaker.allow_request?
    end

    def test_allow_request_when_at_threshold
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 50,
        request_volume_threshold: 2,
      })
      metrics = CircuitBreaker::Metrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      refute circuit_breaker.allow_request?
    end

    def test_allow_request_when_under_request_volume_threshold
      config = CircuitBreaker::Config.new(request_volume_threshold: 5)
      metrics = CircuitBreaker::Metrics.new
      metrics = CircuitBreaker::Metrics.new
      4.times { metrics.mark_failure }
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      assert circuit_breaker.allow_request?
    end

    def test_allow_request_with_circuit_open_but_after_sleep_window_ms
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 49,
        request_volume_threshold: 2,
        sleep_window_ms: 5000,
      })
      metrics = CircuitBreaker::Metrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      refute circuit_breaker.allow_request?

      Timecop.freeze(Time.now + 4) do
        refute circuit_breaker.allow_request?
      end

      Timecop.freeze(Time.now + 5) do
        refute circuit_breaker.allow_request?
      end

      Timecop.freeze(Time.now + 6) do
        assert circuit_breaker.allow_request?
      end
    end

    def test_mark_success
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 49,
        request_volume_threshold: 2,
      })
      metrics = CircuitBreaker::Metrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      refute circuit_breaker.allow_request?
      circuit_breaker.mark_success
      assert circuit_breaker.allow_request?
    end

    def test_mark_failure
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 49,
        request_volume_threshold: 2,
      })
      metrics = CircuitBreaker::Metrics.new
      metrics.mark_success
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)

      assert circuit_breaker.allow_request?
      assert_equal 0, metrics.failures
      circuit_breaker.mark_failure
      refute circuit_breaker.allow_request?
      assert_equal 1, metrics.failures
    end
  end
end
