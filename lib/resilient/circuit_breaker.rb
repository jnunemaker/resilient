require "resilient/circuit_breaker/rolling_metrics"
require "resilient/circuit_breaker/config"

module Resilient
  class CircuitBreaker
    def initialize(config: Config.new, metrics: RollingMetrics.new)
      @open = false
      @opened_at = 0
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
      @opened_at = Time.now.to_i
      @open = true
    end

    def close_circuit
      @opened_at = 0
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
      try_next_request_at = @opened_at + @config.sleep_window_seconds
      now = Time.now.to_i

      if @open && now > try_next_request_at
        @opened_at = now + @config.sleep_window_seconds
        true
      else
        false
      end
    end
  end
end
