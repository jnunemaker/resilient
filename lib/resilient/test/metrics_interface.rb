module Resilient
  class Test
    module MetricsInterface
      def test_responds_to_success
        assert_respond_to @object, :success
      end

      def test_success_returns_nothing
        assert_nil @object.success
      end

      def test_responds_to_failure
        assert_respond_to @object, :failure
      end

      def test_failure_returns_nothing
        assert_nil @object.failure
      end

      def test_responds_to_successes
        assert_respond_to @object, :successes
      end

      def test_responds_to_failures
        assert_respond_to @object, :failures
      end

      def test_responds_to_requests
        assert_respond_to @object, :requests
      end

      def test_responds_to_error_percentage
        assert_respond_to @object, :error_percentage
      end

      def test_responds_to_reset
        assert_respond_to @object, :reset
      end

      def test_reset_returns_nothing
        assert_nil @object.reset
      end
    end
  end
end
