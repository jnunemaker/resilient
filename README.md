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
circuit_breaker.run do
  # some database or flaky service
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
