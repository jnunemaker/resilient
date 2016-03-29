require "test_helper"
require "resilient/circuit_breaker"
require "resilient/test/circuit_breaker_interface"

module Resilient
  class KeyTest < Test
    def test_wrap_with_string
      key = Key.wrap("test")
      assert_instance_of Key, key
      assert_equal "test", key.name
    end

    def test_wrap_with_instance
      original_key = Key.new("test")
      key = Key.wrap(original_key)
      assert_instance_of Key, key
      assert original_key.equal?(key)
    end

    def test_initialize_with_string
      key = Key.new("test")
      assert_equal "test", key.name
    end

    def test_initialize_with_symbol
      assert_raises TypeError do
        Key.new(:test)
      end
    end

    def test_hash
      name = "test"
      key = Key.new(name)
      assert_equal name.hash, key.hash
    end

    def test_equality
      key_a = Key.new("a")
      key_b = Key.new("b")
      other_key_a = Key.new("a")
      not_key = Object.new

      assert key_a.eql?(other_key_a)
      refute key_a.eql?(not_key)
      refute key_a.eql?(key_b)

      assert key_a == other_key_a
      refute key_a == not_key
      refute key_a == key_b
    end

    def test_as_hash_key
      key_a = Key.new("a")
      key_b = Key.new("b")
      other_key_a = Key.new("a")
      hash = {}
      hash[key_a] = "a"
      hash[other_key_a] = "other_a"
      hash[key_b] = "b"

      assert_equal "other_a", hash[key_a]
      assert_equal "other_a", hash[other_key_a]
      assert_equal "b", hash[key_b]
    end
  end
end
