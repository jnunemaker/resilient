require "test_helper"

class ResiliencyTest < Minitest::Test
  def test_that_it_has_a_version_number
    refute_nil ::Resiliency::VERSION
  end
end
