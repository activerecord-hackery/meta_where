require 'meta_where/condition_operators'

module MetaWhere
  class Not
    include ConditionOperators

    attr_reader :expr

    def initialize(expr)
      @expr = expr
    end
  end
end