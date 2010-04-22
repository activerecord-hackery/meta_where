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
    def to_predicate(builder, parent = nil)
      condition1.to_predicate(builder, parent).or(condition2.to_predicate(builder, parent))
    end
  end
  
  class And < Compound
    def to_predicate(builder, parent = nil)
      condition1.to_predicate(builder, parent).and(condition2.to_predicate(builder, parent))
    end
  end
end