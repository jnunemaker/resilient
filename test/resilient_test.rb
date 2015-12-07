require "test_helper"
require "resiliency"

class ResiliencyTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Resiliency::VERSION
  end
end
