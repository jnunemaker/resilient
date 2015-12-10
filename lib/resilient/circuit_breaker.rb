require "resilient/circuit_breaker/metrics"
require "resilient/circuit_breaker/properties"

module Resilient
  class CircuitBreaker
    attr_reader :metrics
    attr_reader :properties
    attr_reader :open
    attr_reader :opened_or_last_checked_at_epoch

    def initialize(open: false, properties: Properties.new, metrics: Metrics.new)
      @open = open
      @opened_or_last_checked_at_epoch = 0
      @properties = properties
      @metrics = if metrics
        metrics
      else
        Metrics.new({
          number_of_buckets: properties.number_of_buckets,
          bucket_size_in_seconds: properties.bucket_size_in_seconds,
        })
      end
    end

    def allow_request?
      default_payload = {
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

    def mark_success
      default_payload = {
        closed_the_circuit: false,
      }

      instrument("resilient.circuit_breaker.mark_success", default_payload) { |payload|
        if @open
          payload[:closed_the_circuit] = true
          close_circuit
        else
          @metrics.mark_success
        end
        nil
      }
    end

    def mark_failure
      instrument("resilient.circuit_breaker.mark_failure") { |payload|
        @metrics.mark_failure
        nil
      }
    end

    def reset
      instrument("resilient.circuit_breaker.reset") { |payload|
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

    def closed?
      !open?
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
