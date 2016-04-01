# setting up load path
require "pathname"
root_path = Pathname(__FILE__).dirname.join("..").expand_path
lib_path  = root_path.join("lib")
$:.unshift(lib_path)

# by default new is private so people don't use it, this makes it possible to
# use it as resilient checks for this env var prior to privatizing new
ENV["RESILIENT_PUBLICIZE_NEW"] = "1"

# requiring stuff for this example
require "pp"
require "resilient/circuit_breaker"

instance = Resilient::CircuitBreaker.get("example")
instance_using_get = Resilient::CircuitBreaker.get("example")
instance_using_new = Resilient::CircuitBreaker.new("example")

puts "instance equals instance_using_get: #{instance.equal?(instance_using_get)}"
puts "instance equals instance_using_new: #{instance.equal?(instance_using_new)}"

instance.properties.request_volume_threshold.times do
  instance.failure
end

puts "instance allow_request?: #{instance.allow_request?}"
puts "instance_using_get allow_request?: #{instance_using_get.allow_request?}"

# this instance allows the request because it isn't sharing internal state and
# metrics due to being a new allocated instance; the for instance does not
# suffer this because it looks up instances in a registry rather than always
# generating a new instance even if you use the exact same key as it bypasses
# the registry
puts "instance_using_new allow_request?: #{instance_using_new.allow_request?}"

# instance equals instance_using_get: true
# instance equals instance_using_new: false
# instance allow_request?: false
# instance_using_get allow_request?: false
# instance_using_new allow_request?: true
