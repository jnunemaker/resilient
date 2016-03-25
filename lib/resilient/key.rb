module Resilient
  class Key
    attr_reader :name

    def initialize(name)
      @name = name.to_s
    end

    def ==(other)
      self.class == other.class && name == other.name
    end
    alias_method :eql?, :==

    def hash
      @name.hash
    end
  end
end
