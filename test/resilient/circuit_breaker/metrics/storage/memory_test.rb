require "test_helper"
require "resilient/circuit_breaker/config"

module Resilient
  class CircuitBreaker
    class Metrics
      module Storage
        class MemoryTest < Resilient::Test
          def setup
            @object = Memory.new
          end

          include MetricsStorageInterfaceTest
        end
      end
    end
  end
end
