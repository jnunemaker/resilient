require "resilient/instrumenters/noop"

module Resilient
  class CircuitBreaker
    class Properties
      # allows forcing the circuit open (stopping all requests)
      attr_reader :force_open

      # allows ignoring errors and therefore never trip "open"
      # (ie. allow all traffic through); normal instrumentation will still
      # happen, thus allowing you to "test" configuration live without impact
      attr_reader :force_closed

      # what to use to instrument all events that happen
      # (ie: ActiveSupport::Notifications)
      attr_reader :instrumenter

      # seconds after tripping circuit before allowing retry
      attr_reader :sleep_window_seconds

      # number of requests that must be made within a statistical window before
      # open/close decisions are made using stats
      attr_reader :request_volume_threshold

      # % of "marks" that must be failed to trip the circuit
      attr_reader :error_threshold_percentage

      # number of seconds in the statistical window
      attr_reader :window_size_in_seconds

      # size of buckets in statistical window
      attr_reader :bucket_size_in_seconds

      def initialize(options = {})
        @force_open = options.fetch(:force_open, false)
        @force_closed = options.fetch(:force_closed, false)
        @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
        @sleep_window_seconds = options.fetch(:sleep_window_seconds, 5)
        @request_volume_threshold = options.fetch(:request_volume_threshold, 20)
        @error_threshold_percentage = options.fetch(:error_threshold_percentage, 50)
        @window_size_in_seconds = options.fetch(:window_size_in_seconds, 60)
        @bucket_size_in_seconds = options.fetch(:bucket_size_in_seconds, 10)
      end
    end
  end
end
