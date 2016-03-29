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

      def initialize(source = nil)
        @source = source || {}
      end

      # Setup default to new instance.
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
        @source.clear
        nil
      end
    end
  end
end
