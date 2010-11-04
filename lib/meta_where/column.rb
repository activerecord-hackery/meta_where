module MetaWhere
  class Column
    attr_reader :column, :method

    def initialize(column, method)
      @column = column
      @method = method
    end

    def %(value)
      MetaWhere::Condition.new(column, value, method)
    end

    def ==(other_column)
      other_column.is_a?(Column)    &&
      other_column.column == column &&
      other_column.method == method
    end

    alias_method :eql?, :==

    def hash
      [column, method].hash
    end

    # Play nicely with expand_hash_conditions_for_aggregates
    def to_sym
      "#{column}.#{method}".to_sym
    end
  end
end