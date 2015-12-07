module Resiliency
  class CircuitBreaker
    class Config
      attr_reader :error_threshold_percentage
      attr_reader :sleep_window_ms
      attr_reader :request_volume_threshold
      attr_reader :force_open
      attr_reader :force_closed

      def initialize(options = {})
        @error_threshold_percentage = options.fetch(:error_threshold_percentage, 50)
        @sleep_window_ms = options.fetch(:sleep_window_ms, 5000)
        @request_volume_threshold = options.fetch(:request_volume_threshold, 20)
        @force_open = options.fetch(:force_open, false)
        @force_closed = options.fetch(:force_closed, false)
      end
    end
  end
end
