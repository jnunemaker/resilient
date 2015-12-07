# Resilient

Some tools for resilient in ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "resilient"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resilient

## Usage

```ruby
require "resilient"

# default config for circuit
circuit_breaker = Resilient::CircuitBreaker.new
if circuit_breaker.request_allowed?
  begin
    # do something expensive
    circuit_breaker.mark_success
  rescue => boom
    # do fallback
    circuit_breaker.mark_failure
  end
else
  # do fallback
end

```

customize config of circuit:

```ruby
config = Resilient::CircuitBreaker::Config.new({
  # at what percentage of errors should we open the circuit
  error_threshold_percentage: 50,
  # do not try request again for 5 seconds
  sleep_window_ms: 5000,
  # do not open circuit until at least 5 requests have happened
  request_volume_threshold: 5,
})
circuit_breaker = Resilient::CircuitBreaker.new(config: config)
# etc etc etc
```

force the circuit to be always open:

```ruby
config = Resilient::CircuitBreaker::Config.new(force_open: true)
circuit_breaker = Resilient::CircuitBreaker.new(config: config)
# etc etc etc
```

force the circuit to be always closed:

```ruby
config = Resilient::CircuitBreaker::Config.new(force_closed: true)
circuit_breaker = Resilient::CircuitBreaker.new(config: config)
# etc etc etc
```

customize rolling window to be 10 buckets of 1 second each (10 seconds in all):

```ruby
metrics = Resilient::CircuitBreaker::RollingMetrics.new({
  number_of_buckets: 10,
  bucket_size_in_seconds: 1,
})
circuit_breaker = Resilient::CircuitBreaker.new(metrics: metrics)
# etc etc etc
```

## Development

```bash
# install dependencies
script/bootstrap

# run tests
script/test

# ...or to auto run tests with guard
script/watch

# to get a shell to play in
script/console
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jnunemaker/resilient.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
