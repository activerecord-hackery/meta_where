module MetaWhere
  class Column
    attr_reader :column, :method
    
    def initialize(column, method)
      @column = column.to_s
      @method = MetaWhere::METHOD_ALIASES[method.to_s] || method
    end
    
    # Play "nicely" with expand_hash_conditions_for_aggregates
    def to_sym
      self
    end
  end
end