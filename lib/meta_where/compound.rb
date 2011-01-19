require 'meta_where/condition_operators'

module MetaWhere
  class Compound
    include ConditionOperators

    attr_reader :condition1, :condition2

    def initialize(condition1, condition2)
      @condition1 = condition1
      @condition2 = condition2
    end
  end

  class Or < Compound
  end

  class And < Compound
  end
end
