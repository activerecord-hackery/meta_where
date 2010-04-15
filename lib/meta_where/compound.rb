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
    def to_predicate(table)
      condition1.to_predicate(table).or(condition2.to_predicate(table))
    end
  end
  
  class And < Compound
    def to_predicate(table)
      condition1.to_predicate(table).and(condition2.to_predicate(table))
    end
  end
end