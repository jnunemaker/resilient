module Resiliency
  class CircuitBreaker
    class Metrics
      attr_reader :successes
      attr_reader :failures

      def initialize
        @failures = 0
        @successes = 0
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
      @config = config
      @metrics = metrics
    end

    def allow_request?
      !open?
    end

    def open?
      return true if @open
      return true if under_request_volume_threshold?
      return false if under_error_threshold_percentage?

      @open = true
    end

    private

    def under_request_volume_threshold?
      @metrics.requests < @config.request_volume_threshold
    end

    def under_error_threshold_percentage?
      @metrics.error_percentage < @config.error_threshold_percentage
    end
  end
end
