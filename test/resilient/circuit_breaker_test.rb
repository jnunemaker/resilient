require "test_helper"
require "resilient/circuit_breaker"
require "resilient/test/circuit_breaker_interface"

module Resilient
  class CircuitBreakerTest < Test
    def setup
      super
      @object = CircuitBreaker.get(key: Resilient::Key.new("object"))
    end

    include Test::CircuitBreakerInterface

    def test_get
      first_initialization = CircuitBreaker.get(key: Resilient::Key.new("longmire"))
      assert_instance_of CircuitBreaker, first_initialization

      second_initialization = CircuitBreaker.get(key: Resilient::Key.new("longmire"))
      assert_instance_of CircuitBreaker, second_initialization
      assert first_initialization.equal?(second_initialization),
        "#{first_initialization.inspect} is not the exact same object as #{second_initialization.inspect}"

      symbol_initialization = CircuitBreaker.get(key: Resilient::Key.new(:longmire))
      assert_instance_of CircuitBreaker, symbol_initialization
      assert first_initialization.equal?(symbol_initialization),
        "#{first_initialization.inspect} is not the exact same object as #{symbol_initialization.inspect}"

      string_initialization = CircuitBreaker.get(key: "longmire")
      assert_instance_of CircuitBreaker, string_initialization
      assert first_initialization.equal?(string_initialization),
        "#{first_initialization.inspect} is not the exact same object as #{string_initialization.inspect}"
    end

    def test_get_with_nil_key
      assert_raises ArgumentError do
        CircuitBreaker.get(key: nil)
      end
    end

    def test_get_with_different_properties_than_initially_provided
      key = Resilient::Key.new("longmire")
      original_properties = CircuitBreaker::Properties.new(error_threshold_percentage: 10)
      circuit_breaker = CircuitBreaker.get(key: key, properties: original_properties)

      different_properties = CircuitBreaker::Properties.new(error_threshold_percentage: 15)
      different_properties_circuit_breaker = CircuitBreaker.get(key: key, properties: different_properties)

      assert_equal original_properties.error_threshold_percentage,
        different_properties_circuit_breaker.properties.error_threshold_percentage
    end

    def test_new
      assert_raises NoMethodError do
        CircuitBreaker.new(key: Resilient::Key.new("test"))
      end
    end

    def test_key
      assert_equal "object", @object.key.name
    end

    def test_allow_request_when_under_error_threshold_percentage
      properties = CircuitBreaker::Properties.new(default_test_properties_options({
        error_threshold_percentage: 51,
      }))
      circuit_breaker = CircuitBreaker.get(properties: properties, key: Resilient::Key.new("test"))
      circuit_breaker.success
      circuit_breaker.failure

      assert circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_allow_request_when_over_error_threshold_percentage
      properties = CircuitBreaker::Properties.new(default_test_properties_options({
        error_threshold_percentage: 49,
      }))
      circuit_breaker = CircuitBreaker.get(properties: properties, key: Resilient::Key.new("test"))
      circuit_breaker.success
      circuit_breaker.failure

      refute circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_allow_request_when_at_error_threshold_percentage
      properties = CircuitBreaker::Properties.new(default_test_properties_options({
        error_threshold_percentage: 50,
      }))
      circuit_breaker = CircuitBreaker.get(properties: properties, key: Resilient::Key.new("test"))
      circuit_breaker.success
      circuit_breaker.failure

      refute circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_allow_request_when_under_request_volume_threshold
      properties = CircuitBreaker::Properties.new(default_test_properties_options({
        request_volume_threshold: 5,
      }))
      circuit_breaker = CircuitBreaker.get(properties: properties, key: Resilient::Key.new("test"))
      4.times { circuit_breaker.metrics.failure }

      assert circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_allow_request_with_circuit_open_but_after_sleep_window_seconds
      now = Time.now
      properties = CircuitBreaker::Properties.new(default_test_properties_options({
        error_threshold_percentage: 49,
        sleep_window_seconds: 5,
      }))
      circuit_breaker = CircuitBreaker.get(properties: properties, key: Resilient::Key.new("test"))
      circuit_breaker.success
      circuit_breaker.failure

      assert_equal 0, circuit_breaker.opened_or_last_checked_at_epoch

      Timecop.freeze(now) do
        refute circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)
        assert_equal now.to_i, circuit_breaker.opened_or_last_checked_at_epoch
      end

      Timecop.freeze(now + properties.sleep_window_seconds - 1) do
        refute circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)
        assert_equal now.to_i, circuit_breaker.opened_or_last_checked_at_epoch
      end

      Timecop.freeze(now + properties.sleep_window_seconds) do
        refute circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)
        assert_equal now.to_i, circuit_breaker.opened_or_last_checked_at_epoch
      end

      Timecop.freeze(now + properties.sleep_window_seconds + 1) do
        assert circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)

        assert_equal (now + properties.sleep_window_seconds + 1).to_i,
          circuit_breaker.opened_or_last_checked_at_epoch
      end
    end

    def test_allow_request_when_forced_open_but_under_threshold
      properties = CircuitBreaker::Properties.new(default_test_properties_options({
        error_threshold_percentage: 51,
        force_open: true,
      }))
      circuit_breaker = CircuitBreaker.get(properties: properties, key: Resilient::Key.new("test"))
      circuit_breaker.success
      circuit_breaker.failure

      refute circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_allow_request_when_forced_closed_but_over_threshold
      properties = CircuitBreaker::Properties.new(default_test_properties_options({
        error_threshold_percentage: 49,
        request_volume_threshold: 0,
        force_closed: true,
      }))
      circuit_breaker = CircuitBreaker.get(properties: properties, key: Resilient::Key.new("test"))
      circuit_breaker.success
      circuit_breaker.failure

      assert circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_success_when_open_does_reset_metrics
      metrics = Minitest::Mock.new
      circuit_breaker = CircuitBreaker.get(open: true, metrics: metrics, key: Resilient::Key.new("test"))

      metrics.expect :reset, nil
      circuit_breaker.success
      metrics.verify
    end

    def test_success_when_not_open_calls_success_on_metrics
      metrics = Minitest::Mock.new
      circuit_breaker = CircuitBreaker.get(open: false, metrics: metrics, key: Resilient::Key.new("test"))

      metrics.expect :success, nil
      circuit_breaker.success
      metrics.verify
    end

    def test_failure_calls_failure_on_metrics
      metrics = Minitest::Mock.new
      circuit_breaker = CircuitBreaker.get(metrics: metrics, key: Resilient::Key.new("test"))

      metrics.expect :failure, nil
      circuit_breaker.failure
      metrics.verify
    end

    def test_reset_calls_reset_on_metrics
      metrics = Minitest::Mock.new
      circuit_breaker = CircuitBreaker.get(metrics: metrics, key: Resilient::Key.new("test"))

      metrics.expect :reset, nil
      circuit_breaker.reset
      metrics.verify
    end

    def test_reset_sets_open_to_false
      circuit_breaker = CircuitBreaker.get(key: Resilient::Key.new("test"))
      circuit_breaker.reset

      assert_equal false, circuit_breaker.open
    end

    def test_reset_sets_opened_or_last_checked_at_epoch_to_zero
      circuit_breaker = CircuitBreaker.get(key: Resilient::Key.new("test"))
      circuit_breaker.reset

      assert_equal 0, circuit_breaker.opened_or_last_checked_at_epoch
    end

    private

    # Returns a Hash of default properties options set in a way that all the short
    # circuit properties options are turned off.
    def default_test_properties_options(options = {})
      {
        request_volume_threshold: 0,
        force_closed: false,
        force_open: false,
      }.merge(options)
    end
  end
end
