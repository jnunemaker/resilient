# setting up load path
require "pathname"
root_path = Pathname(__FILE__).dirname.join("..").expand_path
lib_path  = root_path.join("lib")
$:.unshift(lib_path)

# requiring stuff for this example
require "pp"
require "resilient/circuit_breaker"

circuit_breaker = Resilient::CircuitBreaker.get("example", {
  sleep_window_seconds: 5,
  request_volume_threshold: 20,
  error_threshold_percentage: 10,
  window_size_in_seconds: 60,
  bucket_size_in_seconds: 1,
})

iterations = 0
loop do
  if circuit_breaker.allow_request?
    begin
      puts "request allowed"
      raise if rand(100) < 10
      puts "request succeeded"
      circuit_breaker.success
    rescue => boom
      puts "request failed"
      circuit_breaker.failure
    end
  else
    puts "request denied"
  end
  puts "\n"
  sleep 0.1
  iterations += 1

  if iterations % 10 == 0
    p successes: circuit_breaker.metrics.successes, failures: circuit_breaker.metrics.failures, error_percentage: circuit_breaker.metrics.error_percentage, buckets: circuit_breaker.metrics.buckets.length
  end
end
