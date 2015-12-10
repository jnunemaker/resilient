module Resilient
  class CircuitBreaker
    class Metrics
      module Storage
        class Memory
          attr_reader :source

          def initialize
            @source = Hash.new { |h, k| h[k] = Hash.new(0) }
          end

          def increment(buckets, keys)
            Array(buckets).each do |bucket|
              Array(keys).each do |key|
                @source[bucket][key] += 1
              end
            end
          end

          def sum(buckets, keys)
            response = Hash.new(0)
            Array(buckets).each do |bucket|
              Array(keys).each do |key|
                response[key] += @source[bucket][key]
              end
            end
            response
          end

          def prune(buckets, keys)
            Array(buckets).each do |bucket|
              @source.delete(bucket)
            end
          end
        end
      end
    end
  end
end
