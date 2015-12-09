# Resilient

Some tools for resilient in ruby. For now, just a circuit breaker (~~stolen from~~ based on [hystrix](https://github.com/netflix/hystrix)). Soon much more...

Nothing asynchronous or thread safe yet either.

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
require "resilient/circuit_breaker"

# default config for circuit
circuit_breaker = Resilient::CircuitBreaker.new
if circuit_breaker.allow_request?
  begin
    # do something expensive
    circuit_breaker.mark_success
  rescue => boom
    circuit_breaker.mark_failure
    # do fallback
  end
else
  # do fallback
end
```

customize config of circuit:

```ruby
config = Resilient::CircuitBreaker::RollingConfig.new({
  # at what percentage of errors should we open the circuit
  error_threshold_percentage: 50,
  # do not try request again for 5 seconds
  sleep_window_seconds: 5,
  # do not open circuit until at least 5 requests have happened
  request_volume_threshold: 5,
})
circuit_breaker = Resilient::CircuitBreaker.new(config: config)
# etc etc etc
```

force the circuit to be always open:

```ruby
config = Resilient::CircuitBreaker::RollingConfig.new(force_open: true)
circuit_breaker = Resilient::CircuitBreaker.new(config: config)
# etc etc etc
```

force the circuit to be always closed:

```ruby
config = Resilient::CircuitBreaker::RollingConfig.new(force_closed: true)
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
