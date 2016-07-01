# setting up load path
require "pathname"
root_path = Pathname(__FILE__).dirname.join("..").expand_path
lib_path  = root_path.join("lib")
$:.unshift(lib_path)

# requiring stuff for this example
require "pp"
require "minitest/autorun"
require "resilient/circuit_breaker"
require "resilient/test/metrics_interface"

# Metrics class that closes circuit on every success call and opens circuit for
# sleep_window_seconds on every failure.
class BinaryMetrics
  def initialize(options = {})
    reset
  end

  def success
    reset
    nil
  end

  def failure
    @closed = false
    nil
  end

  def reset
    @closed = true
    nil
  end

  def under_request_volume_threshold?(request_volume_threshold)
    false
  end

  def under_error_threshold_percentage?(error_threshold_percentage)
    @closed
  end
end

class BinaryMetricsTest < Minitest::Test
  def setup
    @object = BinaryMetrics.new
  end

  include Resilient::Test::MetricsInterface
end

circuit_breaker = Resilient::CircuitBreaker.get("example", {
  sleep_window_seconds: 1,
  metrics: BinaryMetrics.new,
})

# success
if circuit_breaker.allow_request?
  begin
    puts "do expensive thing"
    circuit_breaker.success
  rescue => boom
    # won't get here in this example
    circuit_breaker.failure
  end
else
  raise "will not get here"
end

# failure
if circuit_breaker.allow_request?
  begin
    raise
  rescue => boom
    circuit_breaker.failure
    puts "failed slow, do fallback"
  end
else
  raise "will not get here"
end

# fail fast
if circuit_breaker.allow_request?
  raise "will not get here"
else
  puts "failed fast, do fallback"
end

start = Time.now

while (Time.now - start) < 3
  if circuit_breaker.allow_request?
    puts "doing a single attempt as we've failed fast for sleep_window_seconds"
    break
  else
    puts "failed fast, do fallback"
  end
  sleep rand(0.1)
end

if circuit_breaker.allow_request?
  raise "will not get here"
else
  puts "request denied because single request has not been marked success yet"
end

puts "marking single request as success"
circuit_breaker.success

if circuit_breaker.allow_request?
  puts "circuit reset and back closed now, allowing requests"
else
  raise "will not get here"
end
