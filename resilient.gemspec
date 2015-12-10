# coding: utf-8
lib = File.expand_path("../lib", __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require "resilient/version"

Gem::Specification.new do |spec|
  spec.name          = "resilient"
  spec.version       = Resilient::VERSION
  spec.authors       = ["John Nunemaker"]
  spec.email         = ["nunemaker@gmail.com"]

  spec.summary       = %q{toolkit for resilient ruby apps}
  spec.homepage      = "https://github.com/jnunemaker/resilient"
  spec.license       = "MIT"

  spec.files         = `git ls-files -z`.split("\x0").reject { |f| f.match(%r{^(test|spec|features)/}) }
  spec.bindir        = "exe"
  spec.executables   = spec.files.grep(%r{^exe/}) { |f| File.basename(f) }
  spec.require_paths = ["lib"]

  spec.add_development_dependency "bundler", "~> 1.10"
  spec.add_development_dependency "minitest", "~> 5.8"
  spec.add_development_dependency "timecop", "~> 0.8.0"
end
