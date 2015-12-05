module Resiliency
  class CircuitBreaker
    class Metrics
      attr_reader :successes
      attr_reader :failures

      def initialize
        reset
      end

      def mark_success
        @successes += 1
      end

      def mark_failure
        @failures += 1
      end

      def requests
        @failures + @successes
      end

      def error_percentage
        ((@failures / requests.to_f) * 100).to_i
      end

      def reset
        @failures = 0
        @successes = 0
      end
    end

    class Config
      attr_reader :error_threshold_percentage
      attr_reader :sleep_window_ms
      attr_reader :request_volume_threshold

      def initialize(options = {})
        @error_threshold_percentage = options.fetch(:error_threshold_percentage, 50)
        @sleep_window_ms = options.fetch(:sleep_window_ms, 5000)
        @request_volume_threshold = options.fetch(:request_volume_threshold, 20)
      end
    end

    def initialize(open: false, config: Config.new, metrics: Metrics.new)
      @open = open
      @opened_at = 0
      @config = config
      @metrics = metrics
    end

    def allow_request?
      !open? || allow_single_request?
    end

    def open?
      return true if @open
      return false if under_request_volume_threshold?
      return false if under_error_threshold_percentage?

      @opened_at = now_in_ms
      @open = true
    end

    def mark_success
      if @open
        @metrics.reset
        @open = false
      end
    end

    private

    def under_request_volume_threshold?
      @metrics.requests < @config.request_volume_threshold
    end

    def under_error_threshold_percentage?
      @metrics.error_percentage < @config.error_threshold_percentage
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
