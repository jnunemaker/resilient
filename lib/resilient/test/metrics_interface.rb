module Resilient
  class Test
    module MetricsInterface
      def test_responds_to_under_request_volume_threshold_predicate
        assert_respond_to @object, :under_request_volume_threshold?
        assert_equal 1, @object.method(:under_request_volume_threshold?).arity
      end

      def test_responds_to_under_error_threshold_percentage_predicate
        assert_respond_to @object, :under_error_threshold_percentage?
        assert_equal 1, @object.method(:under_error_threshold_percentage?).arity
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

      def test_reset_returns_nothing
        assert_nil @object.reset
      end
    end
  end
end
