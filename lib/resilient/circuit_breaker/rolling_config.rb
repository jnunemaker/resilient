require "resilient/instrumenters/noop"

module Resilient
  class CircuitBreaker
    class RollingConfig
      attr_reader :force_open
      attr_reader :force_closed
      attr_reader :instrumenter
      attr_reader :sleep_window_seconds
      attr_reader :request_volume_threshold
      attr_reader :error_threshold_percentage
      attr_reader :number_of_buckets
      attr_reader :bucket_size_in_seconds

      def initialize(options = {})
        @force_open = options.fetch(:force_open, false)
        @force_closed = options.fetch(:force_closed, false)
        @instrumenter = options.fetch(:instrumenter, Instrumenters::Noop)
        @sleep_window_seconds = options.fetch(:sleep_window_seconds, 5)
        @request_volume_threshold = options.fetch(:request_volume_threshold, 20)
        @error_threshold_percentage = options.fetch(:error_threshold_percentage, 50)
        @number_of_buckets = options.fetch(:number_of_buckets, 6)
        @bucket_size_in_seconds = options.fetch(:bucket_size_in_seconds, 10)
      end
    end
  end
end
