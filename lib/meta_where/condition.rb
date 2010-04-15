module MetaWhere
  class Condition
    attr_reader :column, :value, :method
    
    def initialize(column, value, method)
      @column = column.to_s
      @value = value
      @method = MetaWhere::METHOD_ALIASES[method.to_s] || method
    end
    
    # Play "nicely" with expand_hash_conditions_for_aggregates
    def to_sym
      self
    end
  end
end