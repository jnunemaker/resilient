module Resilient
  class CircuitBreaker
    class Registry
      # Internal: Default registry to use for circuit breakers.
      def self.default
        @default
      end

      # Internal: Allows overriding default registry for circuit breakers.
      def self.default=(value)
        @default = value
      end

      # Public: Reset the default registry. This completely wipes all instances
      # by swapping out the default registry for a new one and letting the old
      # one get GC'd. Useful in tests to get a completely clean slate.
      def self.reset
        default.reset
      end

      def initialize(source = nil)
        @source = source || {}
      end

      # Setup new instance as default. Needs to be after initialize so hash gets
      # initialize correctly.
      @default = new

      # Internal: To be used by CircuitBreaker to either get an instance for a
      # key or set a new instance for a key.
      #
      # Raises KeyError if key not found and no block provided.
      def fetch(key, &block)
        if value = @source[key]
          value
        else
          if block_given?
            @source[key] = yield
          else
            @source.fetch(key)
          end
        end
      end

      # Internal: To be used by CircuitBreaker to reset the stored circuit
      # breakers, which should only really be used for cleaning up in
      # test environment.
      def reset
        @source = {}
        nil
      end
    end
  end
end
