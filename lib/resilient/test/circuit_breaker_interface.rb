module Resilient
  class Test
    module CircuitBreakerInterface
      def test_responds_to_key
        assert_respond_to @object, :key
      end

      def test_responds_to_allow_request
        assert_respond_to @object, :allow_request?
      end

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

      def test_responds_to_reset
        assert_respond_to @object, :reset
      end
    end
  end
end
