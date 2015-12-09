require "resilient/circuit_breaker/rolling_metrics"
require "resilient/circuit_breaker/rolling_config"

module Resilient
  class CircuitBreaker
    attr_reader :metrics
    attr_reader :config
    attr_reader :open
    attr_reader :opened_or_last_checked_at_epoch

    def initialize(open: false, config: RollingConfig.new, metrics: RollingMetrics.new)
      @open = open
      @opened_or_last_checked_at_epoch = 0
      @config = config
      @metrics = if metrics
        metrics
      else
        RollingMetrics.new({
          number_of_buckets: config.number_of_buckets,
          bucket_size_in_seconds: config.bucket_size_in_seconds,
        })
      end
    end

    def allow_request?
      default_payload = {
        force_open: false,
        force_closed: false,
      }
      instrument("resilient.circuit_breaker.allow_request", default_payload) { |payload|
        result = if payload[:force_open] = @config.force_open
          false
        else
          if payload[:force_closed] = @config.force_closed
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
        result
      }
    end

    def mark_success
      default_payload = {
        circuit_closed: false,
      }
      instrument("resilient.circuit_breaker.mark_success", default_payload) { |payload|
        if @open
          payload[:circuit_closed] = true
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
      @metrics.requests < @config.request_volume_threshold
    end

    def under_error_threshold_percentage?
      @metrics.error_percentage < @config.error_threshold_percentage
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

      if @open && now > (@opened_or_last_checked_at_epoch + @config.sleep_window_seconds)
        @opened_or_last_checked_at_epoch = now
        true
      else
        false
      end
    end

    def instrument(name, payload = {}, &block)
      config.instrumenter.instrument(name, payload, &block)
    end
  end
end
