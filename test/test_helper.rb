require "minitest/autorun"
require "timecop"
require "pathname"

root = Pathname(__FILE__).dirname.expand_path
Dir[root.join("support", "**", "*.rb")].each { |f| require f }

module Resilient
  class Test < Minitest::Test
    def debug_circuit_breaker(circuit_breaker)
      buckets_debug = circuit_breaker.metrics.buckets.map { |bucket|
        "  %s - %s (%s): %s + %s = %s" % [
          Time.at(bucket.timestamp_start).utc,
          Time.at(bucket.timestamp_end).utc,
          bucket.size_in_seconds,
          bucket.successes,
          bucket.failures,
          bucket.requests,
        ]
      }.join("\n")
      <<-EOS
now: #{Time.now.to_i}
successes: #{circuit_breaker.metrics.successes}
failures: #{circuit_breaker.metrics.failures}
requests: #{circuit_breaker.metrics.requests}
error_percentage: #{circuit_breaker.metrics.error_percentage}%
buckets:
#{buckets_debug}
open: #{circuit_breaker.open}
opened_or_last_checked_at_epoch: #{circuit_breaker.opened_or_last_checked_at_epoch}
EOS
    end
  end
end
