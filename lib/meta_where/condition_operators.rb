module MetaWhere
  module ConditionOperators
    def |(other)
      Or.new(self, other)
    end

    def &(other)
      And.new(self, other)
    end

    def -(other)
      And.new(self, Not.new(other))
    end

    def -@
      Not.new(self)
    end
  end
end