module Resilient
  class Test
    module PropertiesInterface
      def test_responds_to_force_open
        assert_respond_to @object, :force_open
      end

      def test_responds_to_force_closed
        assert_respond_to @object, :force_closed
      end

      def test_responds_to_instrumenter
        assert_respond_to @object, :instrumenter
      end

      def test_responds_to_sleep_window_seconds
        assert_respond_to @object, :sleep_window_seconds
      end

      def test_responds_to_request_volume_threshold
        assert_respond_to @object, :request_volume_threshold
      end

      def test_responds_to_error_threshold_percentage
        assert_respond_to @object, :error_threshold_percentage
      end

      def test_responds_to_bucket_size_in_seconds
        assert_respond_to @object, :bucket_size_in_seconds
      end
    end
  end
end
