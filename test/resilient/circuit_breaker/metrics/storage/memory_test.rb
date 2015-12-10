require "test_helper"
require "resilient/circuit_breaker/metrics/storage/memory"
require "resilient/test/metrics_storage_interface"

module Resilient
  class CircuitBreaker
    class Metrics
      module Storage
        class MemoryTest < Resilient::Test
          def setup
            @object = Memory.new
          end

          include Test::MetricsStorageInterface
        end
      end
    end
  end
end
