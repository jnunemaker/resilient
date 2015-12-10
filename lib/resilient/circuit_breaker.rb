require "resilient/key"
require "resilient/circuit_breaker/metrics"
require "resilient/circuit_breaker/properties"

module Resilient
  class CircuitBreaker
    attr_reader :key
    attr_reader :open
    attr_reader :opened_or_last_checked_at_epoch
    attr_reader :metrics
    attr_reader :properties

    def initialize(key:, open: false, properties: nil, metrics: nil)
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
      default_payload = {
        key: @key,
        force_open: false,
        force_closed: false,
      }

      instrument("resilient.circuit_breaker.allow_request", default_payload) { |payload|
        result = if payload[:force_open] = @properties.force_open
          false
        else
          if payload[:force_closed] = @properties.force_closed
            # we still want to simulate normal behavior/metrics like open, allow
            # single request, etc. so it is possible to test properties in
            # production without impact
            if payload[:open] = open?
              payload[:allow_single_request] = allow_single_request?
            end

            true
          else
            if !(payload[:open] = open?)
              true
            else
              payload[:allow_single_request] = allow_single_request?
            end
          end
        end

        payload[:result] = result
      }
    end

    def success
      default_payload = {
        key: @key,
        closed_the_circuit: false,
      }

      instrument("resilient.circuit_breaker.success", default_payload) { |payload|
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
      default_payload = {
        key: @key,
      }

      instrument("resilient.circuit_breaker.failure", default_payload) { |payload|
        @metrics.failure
        nil
      }
    end

    def reset
      default_payload = {
        key: @key,
      }

      instrument("resilient.circuit_breaker.reset", default_payload) { |payload|
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
      return true if @open
      return false if under_request_volume_threshold?
      return false if under_error_threshold_percentage?

      open_circuit
      true
    end

    def allow_single_request?
      now = Time.now.to_i

      if @open && now > (@opened_or_last_checked_at_epoch + @properties.sleep_window_seconds)
        @opened_or_last_checked_at_epoch = now
        true
      else
        false
      end
    end

    def instrument(name, payload = {}, &block)
      properties.instrumenter.instrument(name, payload, &block)
    end
  end
end
