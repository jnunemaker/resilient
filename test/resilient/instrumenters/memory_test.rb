require "test_helper"
require "resilient/instrumenters/memory"

module Resilient
  module Instrumenters
    class MemoryTest < Test
      def test_initialize
        instrumenter = Memory.new
        assert_equal [], instrumenter.events
      end

      def test_keeps_track_of_events
        name = :foo
        payload = {pay: "load"}
        block_result = :result
        instrumenter = Memory.new
        instrumenter.instrument(name, payload) { block_result }
        event = instrumenter.events.first
        refute_nil event
        assert_equal name, event.name
        assert_equal payload, event.payload
        assert_equal block_result, event.result
      end

      def test_yields_payload_to_block
        yielded = nil
        payload = {pay: "load"}
        instrumenter = Memory.new
        instrumenter.instrument(:foo, payload) { |yielded_payload|
          yielded = yielded_payload
        }
        assert_equal yielded, payload
      end

      def test_dups_payload_to_avoid_mutation
        instrumenter = Memory.new
        payload = {}
        result = instrumenter.instrument(:foo, payload)
        refute instrumenter.events.first.payload.equal?(payload)
      end
    end
  end
end
