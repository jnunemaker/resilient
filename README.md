# Resiliency

Some tools for resiliency in ruby.

## Installation

Add this line to your application's Gemfile:

```ruby
gem "resiliency"
```

And then execute:

    $ bundle

Or install it yourself as:

    $ gem install resiliency

## Usage

```ruby
require "resiliency"

# default config for circuit
circuit_breaker = Resiliency::CircuitBreaker.new
if circuit_breaker.request_allowed?
  begin
    # do something expensive
    circuit_breaker.mark_success
  rescue => boom
    # do fallback
  end
else
  # do fallback
end

# customize config of circuit
config = Resiliency::CircuitBreaker::Config.new({
  # at what percentage of errors should we open the circuit
  error_threshold_percentage: 50,
  # do not try request again for 5 seconds
  sleep_window_ms: 5000,
  # do not open circuit until at least 5 requests have happened
  request_volume_threshold: 5,
})
circuit_breaker = Resiliency::CircuitBreaker.new(config: config)
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

Bug reports and pull requests are welcome on GitHub at https://github.com/jnunemaker/resiliency.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
