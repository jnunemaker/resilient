# Resilient

Some tools to aid in resiliency in Ruby. For now, just a circuit breaker (~~stolen from~~ based on [hystrix](https://github.com/netflix/hystrix)). Soon much more...

Nothing asynchronous or thread safe yet either, but open to it and would like to see more around it in the future. See more here: [jnunemaker/resilient#18](https://github.com/jnunemaker/resilient/issues/18).

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

# default properties for circuit, CircuitBreaker.get is used instead of
# CircuitBreaker.new as `get` keeps a registry of circuits by key to prevent
# creating multiple instances of the same circuit breaker for a key; not using
# `get` means you would have multiple instances of the circuit breaker and thus
# separate state and metrics; you can read more in examples/get_vs_new.rb
circuit_breaker = Resilient::CircuitBreaker.get("example")
if circuit_breaker.allow_request?
  begin
    # do something expensive
    circuit_breaker.success
  rescue => boom
    circuit_breaker.failure
    # do fallback
  end
else
  # do fallback
end
```

customize properties of circuit:

```ruby
circuit_breaker = Resilient::CircuitBreaker.get("example", {
  # at what percentage of errors should we open the circuit
  error_threshold_percentage: 50,
  # do not try request again for 5 seconds
  sleep_window_seconds: 5,
  # do not open circuit until at least 5 requests have happened
  request_volume_threshold: 5,
})
# etc etc etc
```

force the circuit to be always open:

```ruby
circuit_breaker = Resilient::CircuitBreaker.get("example", force_open: true)
# etc etc etc
```

force the circuit to be always closed (great way to test in production with no impact, all instrumentation still runs which means you can measure in production with config and gain confidence while never actually opening a circuit incorrectly):

```ruby
circuit_breaker = Resilient::CircuitBreaker.get("example", force_closed: true)
# etc etc etc
```

customize rolling window to be 10 buckets of 1 second each (10 seconds in all):

```ruby
circuit_breaker = Resilient::CircuitBreaker.get("example", {
  window_size_in_seconds: 10,
  bucket_size_in_seconds: 1,
})
# etc etc etc
```

## Default Properties

Property                        | Default                | Notes
--------------------------------|------------------------|--------
**:force_open**                 | false                  | allows forcing the circuit open (stopping all requests)
**:force_closed**               | false                  | allows ignoring errors and therefore never trip "open" (ie. allow all traffic through); normal instrumentation will still happen, thus allowing you to "test" configuration live without impact
**:instrumenter**               | Instrumenters::Noop    | what to use to instrument all events that happen (ie: ActiveSupport::Notifications)
**:sleep_window_seconds**       | 5                      | seconds after tripping circuit before allowing retry
**:request_volume_threshold**   | 20                     | number of requests that must be made within a statistical window before open/close decisions are made using stats
**:error_threshold_percentage** | 50                     |  % of "marks" that must be failed to trip the circuit
**:window_size_in_seconds**     | 60                     | number of seconds in the statistical window
**:bucket_size_in_seconds**     | 10                     | size of buckets in statistical window
**:metrics**                    | Resilient::Metrics.new | metrics instance used to keep track of success and failure

## Tests

To ensure that you have clean circuit breakers for each test case, be sure to run the following in the setup for your tests (which resets the default registry and thus clears all the registered circuits) either before every test case or at a minimum each test case that uses circuit breakers.

```ruby
Resilient::CircuitBreaker::Registry.reset
```

**Note**: If you use a non-default registry, you'll need to reset that on your own. If you don't know what I'm talking about, you are fine.

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

## Release (for maintainers)

* increment version based on semver
* git commit version change
* script/release (releases to rubygems and git tags)
