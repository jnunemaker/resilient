module Resilient
  class Key
    attr_reader :name

    def initialize(name)
      @name = name
    end
  end
end
