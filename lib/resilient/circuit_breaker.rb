require "resilient/circuit_breaker/rolling_metrics"
require "resilient/circuit_breaker/config"

module Resilient
  class CircuitBreaker
    def initialize(open: false, config: Config.new, metrics: RollingMetrics.new)
      @open = open
      @opened_at = 0
      @config = config
      @metrics = metrics
    end

    def allow_request?
      return false if @config.force_open
      return true if @config.force_closed

      !open? || allow_single_request?
    end

    def mark_success
      close_circuit if @open
    end

    def mark_failure
      @metrics.mark_failure
    end

    private

    def open_circuit
      @opened_at = now_in_ms
      @open = true
    end

    def close_circuit
      @metrics.reset
      @open = false
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
    end

    def allow_single_request?
      now = now_in_ms
      try_next_request_at = @opened_at + @config.sleep_window_ms

      if @open && now > try_next_request_at
        @opened_at = now + @config.sleep_window_ms
        true
      else
        false
      end
    end

    def now_in_ms
      (Time.now.to_f * 1_000).to_i
    end
  end
end
