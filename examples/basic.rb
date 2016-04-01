# setting up load path
require "pathname"
root_path = Pathname(__FILE__).dirname.join("..").expand_path
lib_path  = root_path.join("lib")
$:.unshift(lib_path)

# requiring stuff for this example
require "pp"
require "resilient/circuit_breaker"

circuit_breaker = Resilient::CircuitBreaker.get("example", {
  sleep_window_seconds: 1,
  request_volume_threshold: 10,
  error_threshold_percentage: 25,
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

# trip circuit, imagine this being same as above but in real life...
# also, we have to fail at least the request volume threshold number of times
circuit_breaker.properties.request_volume_threshold.times do
  circuit_breaker.failure
end

# fail fast
if circuit_breaker.allow_request?
  raise "will not get here"
else
  puts "failed fast, do fallback"
end

now = Time.now

while Time.now - now < 3
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
