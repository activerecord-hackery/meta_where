module MetaWhere
  class Column
    attr_reader :column, :method
    
    def initialize(column, method)
      @column = column.to_s
      @method = method.to_s
    end
    
    def %(value)
      MetaWhere::Condition.new(column, value, method)
    end
    
    def eql?(other_column)
      other_column.is_a?(Column)    &&
      column == other_column.column &&
      method == other_column.method
    end
    
    def hash
      (column + '#' + method).hash
    end
    
    # Play "nicely" with expand_hash_conditions_for_aggregates
    def to_sym
      self
    end
  end
end