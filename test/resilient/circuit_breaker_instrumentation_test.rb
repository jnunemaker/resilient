require "test_helper"
require "resilient/circuit_breaker"
require "resilient/instrumenters/memory"
require "resilient/circuit_breaker/properties"
require "resilient/circuit_breaker/metrics/storage/memory"

module Resilient
  class CircuitBreakerInstrumentationTest < Test
    def test_instruments_allow_request
      instrumenter = Instrumenters::Memory.new
      circuit_breaker = CircuitBreaker.get("test", instrumenter: instrumenter)
      assert circuit_breaker.allow_request?
      event = instrumenter.events.detect { |event| event.name =~ /allow_request/ }
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal false, event.payload[:force_open]
      assert_equal false, event.payload[:force_closed]
      assert_equal true, event.payload[:result]

      event = instrumenter.events.reverse.detect { |event| event.name =~ /open/ }
      assert event
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal false, event[:result]

      refute instrumenter.events.detect { |event| event.name =~ /allow_single_request/ }
    end

    def test_instruments_allow_request_force_open
      instrumenter = Instrumenters::Memory.new
      circuit_breaker = CircuitBreaker.get("test", {
        instrumenter: instrumenter,
        force_open: true,
      })
      refute circuit_breaker.allow_request?
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal true, event.payload[:force_open]
      assert_equal false, event.payload[:result]

      refute instrumenter.events.detect { |event| event.name =~ /open/ }
      refute instrumenter.events.detect { |event| event.name =~ /allow_single_request/ }
    end

    def test_instruments_allow_request_force_closed
      instrumenter = Instrumenters::Memory.new
      circuit_breaker = CircuitBreaker.get("test", {
        instrumenter: instrumenter,
        force_closed: true,
      })
      assert circuit_breaker.allow_request?
      event = instrumenter.events.detect { |event| event.name =~ /allow_request/ }
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal true, event.payload[:force_closed]
      assert_equal true, event.payload[:result]

      event = instrumenter.events.reverse.detect { |event| event.name =~ /open/ }
      assert event
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal false, event[:result]

      refute instrumenter.events.detect { |event| event.name =~ /allow_single_request/ }
    end

    def test_instruments_allow_request_force_closed_when_normal_behavior_would_be_open
      instrumenter = Instrumenters::Memory.new
      circuit_breaker = CircuitBreaker.get("test", {
        instrumenter: instrumenter,
        force_closed: true,
        error_threshold_percentage: 50,
        request_volume_threshold: 0,
      })
      circuit_breaker.failure
      assert circuit_breaker.allow_request?
      event = instrumenter.events.detect { |event|
        event.name == "resilient.circuit_breaker.allow_request"
      }
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal false, event.payload[:force_open]
      assert_equal true, event.payload[:force_closed]
      assert_equal true, event.payload[:result]

      event = instrumenter.events.reverse.detect { |event| event.name =~ /open/ }
      assert event
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal true, event[:result]

      event = instrumenter.events.detect { |event| event.name =~ /allow_single_request/ }
      assert event
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal false, event[:result]
    end

    def test_instrument_allow_request_force_closed_when_normal_behavior_would_be_allow_single_request
      instrumenter = Instrumenters::Memory.new
      circuit_breaker = CircuitBreaker.get("test", {
        instrumenter: instrumenter,
        force_closed: true,
        error_threshold_percentage: 50,
        request_volume_threshold: 0,
        sleep_window_seconds: 1,
      })
      circuit_breaker.failure
      assert circuit_breaker.allow_request?

      # force code path through allow single request by moving past sleep threshold
      Timecop.freeze(Time.now + circuit_breaker.properties.sleep_window_seconds + 1) {
        assert circuit_breaker.allow_request?
      }

      event = instrumenter.events.reverse.detect { |event|
        event.name == "resilient.circuit_breaker.allow_request"
      }
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal false, event.payload[:force_open]
      assert_equal true, event.payload[:force_closed]
      assert_equal true, event.payload[:result]

      event = instrumenter.events.reverse.detect { |event| event.name =~ /open/ }
      assert event
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal true, event[:result]

      event = instrumenter.events.reverse.detect { |event| event.name =~ /allow_single_request/ }
      assert event
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal true, event[:result]
    end

    def test_instruments_allow_request_open_true_allow_single_request_false
      instrumenter = Instrumenters::Memory.new
      circuit_breaker = CircuitBreaker.get("test", {
        instrumenter: instrumenter,
        error_threshold_percentage: 50,
        request_volume_threshold: 0,
      })
      circuit_breaker.properties.instrumenter.reset
      circuit_breaker.failure
      refute circuit_breaker.allow_request?
      event = instrumenter.events.detect { |event|
        event.name == "resilient.circuit_breaker.allow_request"
      }
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal false, event.payload[:force_open]
      assert_equal false, event.payload[:force_closed]
      assert_equal false, event.payload[:result]

      event = instrumenter.events.reverse.detect { |event| event.name =~ /open/ }
      assert event
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal true, event[:result]

      event = instrumenter.events.reverse.detect { |event| event.name =~ /allow_single_request/ }
      assert event
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal false, event[:result]
    end

    def test_instruments_allow_request_open_true_allow_single_request_true
      instrumenter = Instrumenters::Memory.new
      circuit_breaker = CircuitBreaker.get("test", {
        instrumenter: instrumenter,
        error_threshold_percentage: 50,
        request_volume_threshold: 0,
        sleep_window_seconds: 1,
      })
      circuit_breaker.failure
      refute circuit_breaker.allow_request?

      # force code path through allow single request by moving past sleep threshold
      Timecop.freeze(Time.now + circuit_breaker.properties.sleep_window_seconds + 1) {
        assert circuit_breaker.allow_request?
      }

      event = instrumenter.events.reverse.detect { |event|
        event.name == "resilient.circuit_breaker.allow_request"
      }
      refute_nil event
      assert_equal "resilient.circuit_breaker.allow_request", event.name
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal false, event.payload[:force_open]
      assert_equal false, event.payload[:force_closed]
      assert_equal true, event.payload[:result]

      event = instrumenter.events.reverse.detect { |event| event.name =~ /open/ }
      assert event
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal true, event[:result]

      event = instrumenter.events.reverse.detect { |event| event.name =~ /allow_single_request/ }
      assert event
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal true, event[:result]
    end

    def test_instruments_success_when_circuit_closed
      instrumenter = Instrumenters::Memory.new
      circuit_breaker = CircuitBreaker.get("test", instrumenter: instrumenter)
      circuit_breaker.success
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.success", event.name
      assert_equal "test", event.payload.fetch(:key).name
      assert_nil event.payload[:closed_the_circuit]
    end

    def test_instruments_success_when_circuit_open
      instrumenter = Instrumenters::Memory.new
      circuit_breaker = CircuitBreaker.get("test", instrumenter: instrumenter)
      circuit_breaker.instance_variable_set("@open", true)
      circuit_breaker.success
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.close", event.name
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal false, event.payload[:open]
      refute_nil event.payload[:interval]
      event = instrumenter.events[1]
      refute_nil event
      assert_equal "resilient.circuit_breaker.success", event.name
      assert_equal "test", event.payload.fetch(:key).name
      assert_equal true, event.payload[:closed_the_circuit]
    end

    def test_instruments_failure
      instrumenter = Instrumenters::Memory.new
      circuit_breaker = CircuitBreaker.get("test", instrumenter: instrumenter)
      circuit_breaker.failure
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.failure", event.name
      assert_equal "test", event.payload.fetch(:key).name
    end

    def test_instruments_reset
      instrumenter = Instrumenters::Memory.new
      circuit_breaker = CircuitBreaker.get("test", instrumenter: instrumenter)
      circuit_breaker.reset
      event = instrumenter.events.first
      refute_nil event
      assert_equal "resilient.circuit_breaker.reset", event.name
      assert_equal "test", event.payload.fetch(:key).name
    end
  end
end
