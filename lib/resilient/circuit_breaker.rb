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
      return false if @config.force_open
      return true if @config.force_closed

      closed? || allow_single_request?
    end

    def mark_success
      if @open
        close_circuit
      else
        @metrics.mark_success
      end
    end

    def mark_failure
      @metrics.mark_failure
    end

    def reset
      @open = false
      @opened_or_last_checked_at_epoch = 0
      @metrics.reset
      nil
    end

    private

    def open_circuit
      @open = true
      @opened_or_last_checked_at_epoch = Time.now.to_i
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
    end

    def closed?
      !open?
    end

    def allow_single_request?
      try_next_request_at = @opened_or_last_checked_at_epoch + @config.sleep_window_seconds
      now = Time.now.to_i

      if @open && now > try_next_request_at
        @opened_or_last_checked_at_epoch = now + @config.sleep_window_seconds
        true
      else
        false
      end
    end
  end
end
