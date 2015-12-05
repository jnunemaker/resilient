require "test_helper"
require "resiliency/circuit_breaker"

module Resiliency
  class CircuitBreakerTest < Minitest::Test
    def test_allow_request_with_circuit_closed
      assert closed_circuit.allow_request?
    end

    def test_allow_request_with_circuit_open
      refute open_circuit.allow_request?
    end

    def test_open_with_circuit_open
      assert open_circuit.open?
    end

    def test_open_with_circuit_closed
      refute closed_circuit.open?
    end

    def test_open_when_over_error_thresold
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 49,
        request_volume_threshold: 2,
      })
      metrics = CircuitBreaker::Metrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)
      assert circuit_breaker.open?
    end

    def test_open_when_under_error_thresold
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 51,
        request_volume_threshold: 2,
      })
      metrics = CircuitBreaker::Metrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)
      refute circuit_breaker.open?
    end

    def test_open_when_at_error_thresold
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 50,
        request_volume_threshold: 2,
      })
      metrics = CircuitBreaker::Metrics.new
      metrics.mark_success
      metrics.mark_failure
      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)
      assert circuit_breaker.open?
    end

    def test_open_when_under_request_volume_threshold
      config = CircuitBreaker::Config.new(request_volume_threshold: 5)
      metrics = CircuitBreaker::Metrics.new
      metrics = CircuitBreaker::Metrics.new
      metrics.mark_failure
      metrics.mark_failure
      metrics.mark_failure
      metrics.mark_failure

      circuit_breaker = CircuitBreaker.new(config: config, metrics: metrics)
      assert circuit_breaker.open?
    end

    private

    def open_circuit
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 49,
        request_volume_threshold: 2,
      })
      metrics = CircuitBreaker::Metrics.new
      metrics.mark_success
      metrics.mark_failure
      CircuitBreaker.new(config: config, metrics: metrics)
    end

    def closed_circuit
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 51,
        request_volume_threshold: 2,
      })
      metrics = CircuitBreaker::Metrics.new
      metrics.mark_success
      metrics.mark_failure
      CircuitBreaker.new(config: config, metrics: metrics)
    end
  end
end
