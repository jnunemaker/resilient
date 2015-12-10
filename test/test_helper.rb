require "minitest/autorun"
require "timecop"
require "pathname"

module Resilient
  class Test < Minitest::Test
    def debug_metrics(metrics, indent: "")
      keys = [:success, :failure]
      result = Hash.new { |h, k| h[k] = Hash.new(0) }
      metrics.buckets.each do |bucket|
        keys.each do |key|
          result[bucket][key] = metrics.storage.sum(bucket, key)[key]
        end
      end

      max_successes = result.values.map { |value| value[:success] }.max || 0
      max_failures = result.values.map { |value| value[:failure] }.max || 0
      max_requests = result.values.map { |value| value[:success] + value[:failure] }.max || 0

      requests_pad = max_requests.to_s.length
      successes_pad = max_successes.to_s.length
      failures_pad = max_failures.to_s.length

      buckets_debug = metrics.buckets.map { |bucket|
        "%s%s - %s (%s): %s + %s = %s" % [
          indent,
          bucket.timestamp_start,
          bucket.timestamp_end,
          bucket.timestamp_end - bucket.timestamp_start + 1,
          result[bucket][:success].to_s.rjust(successes_pad),
          result[bucket][:failure].to_s.rjust(failures_pad),
          (result[bucket][:success] + result[bucket][:failure]).to_s.rjust(requests_pad),
        ]
      }.join("\n")
    end

    def debug_properties(properties, indent: "")
      properties.instance_variables.map { |ivar|
        "%s%s: %s" % [
          indent,
          ivar.to_s.sub("@", ""),
          properties.instance_variable_get(ivar),
        ]
      }.join("\n")
    end

    def debug_circuit_breaker(circuit_breaker)
      <<-EOS
now: #{Time.now.utc}
open: #{circuit_breaker.open}
opened_or_last_checked_at_epoch: #{circuit_breaker.opened_or_last_checked_at_epoch}
requests: #{circuit_breaker.metrics.successes} + #{circuit_breaker.metrics.failures} = #{circuit_breaker.metrics.requests}
error_percentage: #{circuit_breaker.metrics.error_percentage}%
buckets:
#{debug_metrics(circuit_breaker.metrics, indent: "  ")}
properties:
#{debug_properties(circuit_breaker.properties, indent: "  ")}
EOS
    end
  end
end
