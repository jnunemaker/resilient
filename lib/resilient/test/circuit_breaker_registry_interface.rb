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
        original_foo = @object.fetch("foo") { Object.new }
        original_bar = @object.fetch("bar") { Object.new }

        assert_nil @object.reset

        foo = @object.fetch("foo") { Object.new }
        bar = @object.fetch("bar") { Object.new }

        # assert that the objects before and after reset are not the same object
        refute original_foo.equal?(foo)
        refute original_bar.equal?(bar)
      end

      def test_reset_empty_registry
        assert_nil @object.reset
      end
    end
  end
end
