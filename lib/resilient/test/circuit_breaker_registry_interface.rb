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
        assert_nil @object.reset

        @object.fetch("foo") { "bar" }
        @object.fetch("baz") { "wick" }

        assert_nil @object.reset
        assert_raises(KeyError) { @object.fetch("foo") }
        assert_raises(KeyError) { @object.fetch("baz") }
      end
    end
  end
end
