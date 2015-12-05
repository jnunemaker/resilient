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
```

## Development

```bash
script/bootstrap
script/test
```

## Contributing

Bug reports and pull requests are welcome on GitHub at https://github.com/jnunemaker/resiliency.

## License

The gem is available as open source under the terms of the [MIT License](http://opensource.org/licenses/MIT).
