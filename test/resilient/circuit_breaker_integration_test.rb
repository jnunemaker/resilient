require "test_helper"
require "resilient/circuit_breaker"

module Resilient
  class CircuitBreakerIntegrationTest < Resilient::Test
    def test_enough_failures_in_time_window_open_circuit
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 25,
        request_volume_threshold: 0,
        number_of_buckets: 6,
        bucket_size_in_seconds: 10,
      })
      circuit_breaker = CircuitBreaker.new(config: config)
      70.times { circuit_breaker.mark_success }
      assert circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)

      20.times { circuit_breaker.mark_failure }
      assert circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)

      5.times { circuit_breaker.mark_success }
      assert circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)

      5.times { circuit_breaker.mark_failure }
      refute circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_enough_failures_in_time_window_but_under_request_threshold_does_not_open_circuit
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 25,
        request_volume_threshold: 20,
        number_of_buckets: 6,
        bucket_size_in_seconds: 10,
      })
      circuit_breaker = CircuitBreaker.new(config: config)
      18.times { circuit_breaker.mark_failure }
      assert circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)

      2.times { circuit_breaker.mark_failure }
      refute circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_forced_open_does_not_allow_request_even_if_all_successes
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 25,
        request_volume_threshold: 0,
        force_open: true,
      })
      circuit_breaker = CircuitBreaker.new(config: config)
      refute circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)

      20.times { circuit_breaker.mark_success }
      refute circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_forced_close_allows_requests_even_if_all_failures
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 25,
        request_volume_threshold: 0,
        force_closed: true,
      })
      circuit_breaker = CircuitBreaker.new(config: config)
      assert circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)

      20.times { circuit_breaker.mark_failure }
      assert circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_force_open_takes_precedence_over_force_closed
      config = CircuitBreaker::Config.new({
        request_volume_threshold: 0,
        force_closed: true,
        force_open: true,
      })
      circuit_breaker = CircuitBreaker.new(config: config)
      refute circuit_breaker.allow_request?,
        debug_circuit_breaker(circuit_breaker)
    end

    def test_allow_request_denies_for_sleep_seconds_then_allows_single_request_which_if_successful_closes_circuit
      config = CircuitBreaker::Config.new({
        error_threshold_percentage: 25,
        request_volume_threshold: 0,
        number_of_buckets: 6,
        bucket_size_in_seconds: 10,
      })
      circuit_breaker = CircuitBreaker.new(config: config)
      now = Time.now
      bucket1 = now
      bucket2 = now + 10
      bucket3 = now + 20
      bucket4 = now + 30
      bucket5 = now + 40
      bucket6 = now + 50

      Timecop.freeze(bucket1) do
        12.times { circuit_breaker.mark_success }
        2.times { circuit_breaker.mark_failure }
        assert circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)
      end

      Timecop.freeze(bucket2) do
        13.times { circuit_breaker.mark_success }
        3.times { circuit_breaker.mark_failure }
        assert circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)
      end

      Timecop.freeze(bucket3) do
        22.times { circuit_breaker.mark_success }
        10.times { circuit_breaker.mark_failure }
        assert circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)
      end

      Timecop.freeze(bucket4) do
        14.times { circuit_breaker.mark_success }
        3.times { circuit_breaker.mark_failure }
        assert circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)
      end

      Timecop.freeze(bucket5) do
        9.times { circuit_breaker.mark_success }
        4.times { circuit_breaker.mark_failure }
        assert circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)
      end

      Timecop.freeze(bucket6) do
        33.times { circuit_breaker.mark_success }
        12.times { circuit_breaker.mark_failure }
        refute circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)
      end

      # single request is allowed now
      Timecop.freeze(bucket6 + config.sleep_window_seconds + 1) do
        # allow single request through
        assert circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)

        # haven't marked success or failure yet so fail subsequent checks
        refute circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)

        circuit_breaker.mark_success

        # success happened so we allow requests once again
        assert circuit_breaker.allow_request?,
          debug_circuit_breaker(circuit_breaker)
      end
    end
  end
end
