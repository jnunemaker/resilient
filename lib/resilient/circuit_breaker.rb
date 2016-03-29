require "resilient/key"
require "resilient/circuit_breaker/metrics"
require "resilient/circuit_breaker/properties"
require "resilient/circuit_breaker/registry"

module Resilient
  class CircuitBreaker
    # Public: Resets all registered circuit breakers (and thus their state/metrics).
    # Useful for ensuring a clean environment between tests.
    def self.reset
      Registry.default.reset
    end

    # Public: Returns an instance of circuit breaker based on key and registry.
    # Default registry is used if none is provided. If key does not exist, it is
    # registered. If key does exist, it returns registered instance instead of
    # allocating a new instance in order to ensure that state/metrics are the
    # same per key.
    def self.get_instance(key: nil, open: false, properties: nil, metrics: nil, registry: nil)
      (registry || Registry.default).fetch(key) {
        new(key: key, open: open, properties: properties, metrics: metrics)
      }
    end

    unless ENV.key?("RESILIENT_PUBLICIZE_NEW")
      class << self
        private :new
      end
    end

    attr_reader :key
    attr_reader :open
    attr_reader :opened_or_last_checked_at_epoch
    attr_reader :metrics
    attr_reader :properties

    def initialize(key: nil, open: false, properties: nil, metrics: nil)
      # ruby 2.0 does not support required keyword arguments, this gets around that
      raise ArgumentError, "key argument is required" if key.nil?
      @key = key
      @open = open
      @opened_or_last_checked_at_epoch = 0

      @properties = if properties
        properties
      else
        Properties.new
      end

      @metrics = if metrics
        metrics
      else
        Metrics.new({
          window_size_in_seconds: @properties.window_size_in_seconds,
          bucket_size_in_seconds: @properties.bucket_size_in_seconds,
        })
      end
    end

    def allow_request?
      instrument("resilient.circuit_breaker.allow_request", key: @key) { |payload|
        payload[:result] = if payload[:force_open] = @properties.force_open
          false
        else
          # we still want to simulate normal behavior/metrics like open, allow
          # single request, etc. so it is possible to test properties in
          # production without impact using force_closed so we run these here
          # instead of in the else below
          allow_request = !open? || allow_single_request?

          if payload[:force_closed] = @properties.force_closed
            true
          else
            allow_request
          end
        end
      }
    end

    def success
      instrument("resilient.circuit_breaker.success", key: @key) { |payload|
        if @open
          payload[:closed_the_circuit] = true
          close_circuit
        else
          @metrics.success
        end
        nil
      }
    end

    def failure
      instrument("resilient.circuit_breaker.failure", key: @key) { |payload|
        @metrics.failure
        nil
      }
    end

    def reset
      instrument("resilient.circuit_breaker.reset", key: @key) { |payload|
        @open = false
        @opened_or_last_checked_at_epoch = 0
        @metrics.reset
        nil
      }
    end

    private

    def open_circuit
      @opened_or_last_checked_at_epoch = Time.now.to_i
      @open = true
    end

    def close_circuit
      @open = false
      @opened_or_last_checked_at_epoch = 0
      @metrics.reset
    end

    def under_request_volume_threshold?
      @metrics.requests < @properties.request_volume_threshold
    end

    def under_error_threshold_percentage?
      @metrics.error_percentage < @properties.error_threshold_percentage
    end

    def open?
      instrument("resilient.circuit_breaker.open", key: @key) { |payload|
        payload[:result] = if @open
          true
        else
          if under_request_volume_threshold?
            false
          else
            if under_error_threshold_percentage?
              false
            else
              open_circuit
              true
            end
          end
        end
      }
    end

    def allow_single_request?
      instrument("resilient.circuit_breaker.allow_single_request", key: @key) { |payload|
        now = Time.now.to_i

        payload[:result] = if @open && now > (@opened_or_last_checked_at_epoch + @properties.sleep_window_seconds)
          @opened_or_last_checked_at_epoch = now
          true
        else
          false
        end
      }
    end

    def instrument(name, payload = {}, &block)
      properties.instrumenter.instrument(name, payload, &block)
    end
  end
end
