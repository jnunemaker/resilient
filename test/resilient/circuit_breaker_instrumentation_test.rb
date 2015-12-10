require "test_helper"
require "resilient/circuit_breaker"
require "resilient/circuit_breaker/properties"
require "resilient/circuit_breaker/metrics/storage/memory"

module Resilient
  class CircuitBreakerInstrumentationTest < Resilient::Test
    def test_instruments_allow_request
      instrumenter = Instrumenters::Memory.new
      properties = CircuitBreaker::Properties.new({
        instrumenter: instrumenter,
      })
      circuit_breaker = CircuitBreaker.new(properties: properties)
      assert circuit_breaker.allow_request?
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      assert_equal false, event.payload[:force_open]
      assert_equal false, event.payload[:force_closed]
      assert_equal true, event.payload[:result]
      assert_equal false, event.payload[:open]
      assert_equal nil, event.payload[:allow_single_request]
    end

    def test_instruments_allow_request_force_open
      instrumenter = Instrumenters::Memory.new
      properties = CircuitBreaker::Properties.new({
        instrumenter: instrumenter,
        force_open: true,
      })
      circuit_breaker = CircuitBreaker.new(properties: properties)
      refute circuit_breaker.allow_request?
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      assert_equal true, event.payload[:force_open]
      assert_equal false, event.payload[:result]
      assert_equal nil, event.payload[:open]
      assert_equal nil, event.payload[:allow_single_request]
    end

    def test_instruments_allow_request_force_closed
      instrumenter = Instrumenters::Memory.new
      properties = CircuitBreaker::Properties.new({
        instrumenter: instrumenter,
        force_closed: true,
      })
      circuit_breaker = CircuitBreaker.new(properties: properties)
      assert circuit_breaker.allow_request?
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      assert_equal true, event.payload[:force_closed]
      assert_equal true, event.payload[:result]
      assert_equal false, event.payload[:open]
      assert_equal nil, event.payload[:allow_single_request]
    end

    def test_instruments_allow_request_force_closed_when_normal_behavior_would_be_open
      instrumenter = Instrumenters::Memory.new
      properties = CircuitBreaker::Properties.new({
        instrumenter: instrumenter,
        force_closed: true,
        error_threshold_percentage: 50,
        request_volume_threshold: 0,
      })
      circuit_breaker = CircuitBreaker.new(properties: properties)
      circuit_breaker.failure
      assert circuit_breaker.allow_request?
      event = instrumenter.events.detect { |event|
        event.name == "resilient.circuit_breaker.allow_request"
      }
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      assert_equal false, event.payload[:force_open]
      assert_equal true, event.payload[:force_closed]
      assert_equal true, event.payload[:result]
      assert_equal true, event.payload[:open]
      assert_equal false, event.payload[:allow_single_request]
    end

    def test_instrument_allow_request_force_closed_when_normal_behavior_would_be_allow_single_request
      instrumenter = Instrumenters::Memory.new
      properties = CircuitBreaker::Properties.new({
        instrumenter: instrumenter,
        force_closed: true,
        error_threshold_percentage: 50,
        request_volume_threshold: 0,
        sleep_window_seconds: 1,
      })
      circuit_breaker = CircuitBreaker.new(properties: properties)
      circuit_breaker.failure
      assert circuit_breaker.allow_request?

      # force code path through allow single request by moving past sleep threshold
      Timecop.freeze(Time.now + properties.sleep_window_seconds + 1) {
        assert circuit_breaker.allow_request?
      }

      event = instrumenter.events.reverse.detect { |event|
        event.name == "resilient.circuit_breaker.allow_request"
      }
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      assert_equal false, event.payload[:force_open]
      assert_equal true, event.payload[:force_closed]
      assert_equal true, event.payload[:result]
      assert_equal true, event.payload[:open]
      assert_equal true, event.payload[:allow_single_request]
    end

    def test_instruments_allow_request_open_true_allow_single_request_false
      instrumenter = Instrumenters::Memory.new
      properties = CircuitBreaker::Properties.new({
        instrumenter: instrumenter,
        error_threshold_percentage: 50,
        request_volume_threshold: 0,
      })
      circuit_breaker = CircuitBreaker.new(properties: properties)
      circuit_breaker.failure
      refute circuit_breaker.allow_request?
      event = instrumenter.events.detect { |event|
        event.name == "resilient.circuit_breaker.allow_request"
      }
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      assert_equal false, event.payload[:force_open]
      assert_equal false, event.payload[:force_closed]
      assert_equal false, event.payload[:result]
      assert_equal true, event.payload[:open]
      assert_equal false, event.payload[:allow_single_request]
    end

    def test_instruments_allow_request_open_true_allow_single_request_true
      instrumenter = Instrumenters::Memory.new
      properties = CircuitBreaker::Properties.new({
        instrumenter: instrumenter,
        error_threshold_percentage: 50,
        request_volume_threshold: 0,
        sleep_window_seconds: 1,
      })
      circuit_breaker = CircuitBreaker.new(properties: properties)
      circuit_breaker.failure
      refute circuit_breaker.allow_request?

      # force code path through allow single request by moving past sleep threshold
      Timecop.freeze(Time.now + properties.sleep_window_seconds + 1) {
        assert circuit_breaker.allow_request?
      }

      event = instrumenter.events.reverse.detect { |event|
        event.name == "resilient.circuit_breaker.allow_request"
      }
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      assert_equal false, event.payload[:force_open]
      assert_equal false, event.payload[:force_closed]
      assert_equal true, event.payload[:result]
      assert_equal true, event.payload[:open]
      assert_equal true, event.payload[:allow_single_request]
    end

    def test_instruments_success_when_circuit_closed
      instrumenter = Instrumenters::Memory.new
      properties = CircuitBreaker::Properties.new({
        instrumenter: instrumenter,
      })
      circuit_breaker = CircuitBreaker.new(open: false, properties: properties)
      circuit_breaker.success
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.success", event.name
      assert_equal false, event.payload[:closed_the_circuit]
    end

    def test_instruments_success_when_circuit_open
      instrumenter = Instrumenters::Memory.new
      properties = CircuitBreaker::Properties.new({
        instrumenter: instrumenter,
      })
      circuit_breaker = CircuitBreaker.new(open: true, properties: properties)
      circuit_breaker.success
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.success", event.name
      assert_equal true, event.payload[:closed_the_circuit]
    end

    def test_instruments_failure
      instrumenter = Instrumenters::Memory.new
      properties = CircuitBreaker::Properties.new({
        instrumenter: instrumenter,
      })
      circuit_breaker = CircuitBreaker.new(properties: properties)
      circuit_breaker.failure
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.failure", event.name
      expected_payload = {}
      assert_equal expected_payload, event.payload
    end

    def test_instruments_reset
      instrumenter = Instrumenters::Memory.new
      properties = CircuitBreaker::Properties.new({
        instrumenter: instrumenter,
      })
      circuit_breaker = CircuitBreaker.new(properties: properties)
      circuit_breaker.reset
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.reset", event.name
      expected_payload = {}
      assert_equal expected_payload, event.payload
    end
  end
end
