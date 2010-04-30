require 'meta_where/utility'

module MetaWhere
  class Condition
    include MetaWhere::Utility
    
    attr_reader :column, :value, :method
    
    def initialize(column, value, method)
      @column = column.to_s
      @value = value
      @method = (MetaWhere::METHOD_ALIASES[method.to_s] || method).to_s
    end
    
    def to_predicate(builder, parent = nil)
      table = builder.build_table(parent)
      
      unless attribute = table[column]
        raise ::ActiveRecord::StatementInvalid, "No attribute named `#{column}` exists for table `#{table.name}`"
      end

      unless valid_comparison_method?(method)
        raise ::ActiveRecord::StatementInvalid, "No comparison method named `#{method}` exists for column `#{column}`"
      end
      attribute.send(method, *args_for_predicate(method.to_s, value))
    end
    
    def ==(other_condition)
      other_condition.is_a?(Condition) &&
      other_condition.column == column &&
      other_condition.value = value    &&
      other_condition.method == method
    end
    
    alias_method :eql?, :==
    
    def |(other)
      Or.new(self, other)
    end
    
    def &(other)
      And.new(self, other)
    end
    
    # Play "nicely" with expand_hash_conditions_for_aggregates
    def to_sym
      self
    end
  end
  
end