require "test_helper"
require "resilient/instrumenters/noop"

module Resilient
  module Instrumenters
    class NoopTest < Test
      def test_instrument_with_name
        yielded = false
        Noop.instrument(:foo) { yielded = true }
        assert yielded
      end

      def test_instrument_with_name_and_payload
        yielded = false
        Noop.instrument(:foo, {:pay => :load}) { yielded = true }
        assert yielded
      end
    end
  end
end
