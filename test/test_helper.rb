require "minitest/autorun"
require "timecop"
require "pathname"

root = Pathname(__FILE__).dirname.expand_path
Dir[root.join("support", "**", "*.rb")].each { |f| require f }

module Resilient
  class Test < Minitest::Test
    def debug_circuit_breaker(circuit_breaker)
      buckets = circuit_breaker.metrics.buckets

      max_requests = buckets.map { |bucket| bucket.requests }.max || 0
      max_successes = buckets.map { |bucket| bucket.successes }.max || 0
      max_failures = buckets.map { |bucket| bucket.failures }.max || 0

      requests_pad = max_requests.to_s.length
      successes_pad = max_successes.to_s.length
      failures_pad = max_failures.to_s.length

      buckets_debug = buckets.map { |bucket|
        "  %s - %s (%s): %s + %s = %s" % [
          Time.at(bucket.timestamp_start).utc,
          Time.at(bucket.timestamp_end).utc,
          bucket.size_in_seconds,
          bucket.successes.to_s.rjust(successes_pad),
          bucket.failures.to_s.rjust(failures_pad),
          bucket.requests.to_s.rjust(requests_pad),
        ]
      }.join("\n")

      config_debug = circuit_breaker.config.instance_variables.map { |ivar|
        "  %s: %s" % [
          ivar.to_s.sub("@", ""),
          circuit_breaker.config.instance_variable_get(ivar),
        ]
      }.join("\n")

      <<-EOS
now: #{Time.now.utc}
open: #{circuit_breaker.open}
opened_or_last_checked_at_epoch: #{circuit_breaker.opened_or_last_checked_at_epoch}
requests: #{circuit_breaker.metrics.successes} + #{circuit_breaker.metrics.failures} = #{circuit_breaker.metrics.requests}
error_percentage: #{circuit_breaker.metrics.error_percentage}%
buckets:
#{buckets_debug}
config:
#{config_debug}
EOS
    end
  end
end
