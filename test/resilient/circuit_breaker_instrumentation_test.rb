require "test_helper"
require "resilient/circuit_breaker"

module Resilient
  class CircuitBreakerInstrumentationTest < Resilient::Test
    def test_instruments_allow_request
      instrumenter = Instrumenters::Memory.new
      config = CircuitBreaker::RollingConfig.new({
        instrumenter: instrumenter,
      })
      circuit_breaker = CircuitBreaker.new(config: config)
      circuit_breaker.allow_request?
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      expected_payload = {}
      assert_equal expected_payload, event.payload
    end

    def test_instruments_mark_success
      instrumenter = Instrumenters::Memory.new
      config = CircuitBreaker::RollingConfig.new({
        instrumenter: instrumenter,
      })
      circuit_breaker = CircuitBreaker.new(config: config)
      circuit_breaker.mark_success
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.mark_success", event.name
      expected_payload = {}
      assert_equal expected_payload, event.payload
    end

    def test_instruments_mark_failure
      instrumenter = Instrumenters::Memory.new
      config = CircuitBreaker::RollingConfig.new({
        instrumenter: instrumenter,
      })
      circuit_breaker = CircuitBreaker.new(config: config)
      circuit_breaker.mark_failure
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.mark_failure", event.name
      expected_payload = {}
      assert_equal expected_payload, event.payload
    end

    def test_instruments_reset
      instrumenter = Instrumenters::Memory.new
      config = CircuitBreaker::RollingConfig.new({
        instrumenter: instrumenter,
      })
      circuit_breaker = CircuitBreaker.new(config: config)
      circuit_breaker.reset
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.reset", event.name
      expected_payload = {}
      assert_equal expected_payload, event.payload
    end
  end
end
