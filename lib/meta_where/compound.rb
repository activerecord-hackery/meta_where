module MetaWhere
  class Compound
    attr_reader :condition1, :condition2

    def initialize(condition1, condition2)
      @condition1 = condition1
      @condition2 = condition2
    end

    def |(other)
      Or.new(self, other)
    end

    def &(other)
      And.new(self, other)
    end
  end

  class Or < Compound
  end

  class And < Compound
  end
end