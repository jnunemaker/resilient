module Resilient
  class Key

    # Internal: Takes a string name or instance of a Key and always returns a
    # Key instance.
    def self.wrap(string_or_instance)
      case string_or_instance
      when self, NilClass
        string_or_instance
      else
        new(string_or_instance)
      end
    end

    attr_reader :name

    def initialize(name)
      raise TypeError, "name must be a String" unless name.is_a?(String)
      @name = name
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
