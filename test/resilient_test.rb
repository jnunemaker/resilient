require "test_helper"
require "resilient"

module Resilient
  class ResilientTest < Test
    def test_that_it_has_a_version_number
      refute_nil Resilient::VERSION
    end
  end
end
