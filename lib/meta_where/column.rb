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

    def ==(other_column)
      other_column.is_a?(Column)    &&
      other_column.column == column &&
      other_column.method == method
    end

    alias_method :eql?, :==

    def to_attribute(builder, parent = nil)
      column_name = column
      if column_name.include?('.')
        table_name, column_name = column_name.split('.', 2)
        table = Arel::Table.new(table_name, :engine => parent.arel_engine)
      else
        table = builder.build_table(parent)
      end

      unless attribute = table[column_name]
        raise ::ActiveRecord::StatementInvalid, "No attribute named `#{column_name}` exists for table `#{table.name}`"
      end

      attribute.send(method)
    end

    def hash
      [column, method].hash
    end

    # Play nicely with expand_hash_conditions_for_aggregates
    def to_sym
      "#{column}.#{method}".to_sym
    end
  end
end