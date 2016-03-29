# setting up load path
require "pathname"
root_path = Pathname(__FILE__).dirname.join("..").expand_path
lib_path  = root_path.join("lib")
$:.unshift(lib_path)

# requiring stuff for this example
require "pp"
require "resilient/circuit_breaker"

key = Resilient::Key.new("example")
instance = Resilient::CircuitBreaker.for(key: key)
instance_using_for = Resilient::CircuitBreaker.for(key: key)
instance_using_new = Resilient::CircuitBreaker.new(key: key)

puts "instance equals instance_using_for: #{instance.equal?(instance_using_for)}"
puts "instance equals instance_using_new: #{instance.equal?(instance_using_new)}"

instance.properties.request_volume_threshold.times do
  instance.failure
end

puts "instance allow_request?: #{instance.allow_request?}"
puts "instance_using_for allow_request?: #{instance_using_for.allow_request?}"

# this instance allows the request because it isn't sharing internal state and
# metrics due to being a new allocated instance; the for instance does not
# suffer this because it looks up instances in a registry rather than always
# generating a new instance even if you use the exact same key as it bypasses
# the registry
puts "instance_using_new allow_request?: #{instance_using_new.allow_request?}"

# instance equals instance_using_for: true
# instance equals instance_using_new: false
# instance allow_request?: false
# instance_using_for allow_request?: false
# instance_using_new allow_request?: true
