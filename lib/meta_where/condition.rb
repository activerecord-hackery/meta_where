require 'meta_where/utility'

module MetaWhere
  class Condition
    include MetaWhere::Utility

    attr_reader :column, :value, :method

    def initialize(column, value, method)
      @column = column
      @value = value
      @method = (MetaWhere::METHOD_ALIASES[method.to_s] || method).to_s
    end

    def ==(other_condition)
      other_condition.is_a?(Condition) &&
      other_condition.column == column &&
      other_condition.value == value    &&
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