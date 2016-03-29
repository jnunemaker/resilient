module Resilient
  class Test
    module CircuitBreakerRegistryInterface
      def test_responds_to_fetch
        assert_respond_to @object, :fetch
      end

      def test_responds_to_reset
        assert_respond_to @object, :reset
      end

      def test_fetch
        key = "foo"
        value = "bar".freeze

        assert_raises(KeyError) { @object.fetch(key) }
        assert_equal value, @object.fetch(key) { value }
        assert_equal value, @object.fetch(key)
        assert @object.fetch(key).equal?(value)
      end

      def test_reset
        bar_value = Minitest::Mock.new
        wick_value = Minitest::Mock.new
        bar_value.expect :reset, nil, []
        wick_value.expect :reset, nil, []

        @object.fetch("foo") { bar_value }
        @object.fetch("baz") { wick_value }

        assert_nil @object.reset

        bar_value.verify
        wick_value.verify
      end

      def test_reset_empty_registry
        assert_nil @object.reset
      end
    end
  end
end
