module MetaWhere
  class Function
    attr_reader :name, :args
    attr_accessor :table, :alias

    def initialize(name, *args)
      @name = name
      @args = args
    end

    def as(val)
      self.alias = val
      self
    end

    def to_sqlliteral
      Arel.sql(
        ("#{name}(#{(['%s'] * args.size).join(',')})" % contextualize_args) +
        (self.alias ? " AS #{self.alias}" : '')
      )
    end

    alias_method :to_sql, :to_sqlliteral

    MetaWhere::PREDICATES.each do |predication|
      define_method(predication) do
        MetaWhere::Column.new(self, predication)
      end
    end

    MetaWhere::METHOD_ALIASES.each_pair do |aliased, predication|
      define_method(aliased) do
        MetaWhere::Column.new(self, predication)
      end
    end

    def >>(value)
      MetaWhere::Condition.new(self, value, :eq)
    end

    def ^(value)
      MetaWhere::Condition.new(self, value, :not_eq)
    end

    def +(value)
      MetaWhere::Condition.new(self, value, :in)
    end

    def -(value)
      MetaWhere::Condition.new(self, value, :not_in)
    end

    def =~(value)
      MetaWhere::Condition.new(self, value, :matches)
    end

    # Won't work on Ruby 1.8.x so need to do this conditionally
    if respond_to?('!~')
      define_method('!~') do |value|
        MetaWhere::Condition.new(self, value, :does_not_match)
      end
    end

    def >(value)
      MetaWhere::Condition.new(self, value, :gt)
    end

    def >=(value)
      MetaWhere::Condition.new(self, value, :gteq)
    end

    def <(value)
      MetaWhere::Condition.new(self, value, :lt)
    end

    def <=(value)
      MetaWhere::Condition.new(self, value, :lteq)
    end

    # Play "nicely" with expand_hash_conditions_for_aggregates
    def to_sym
      self
    end

    private

    def contextualize_args
      args.map do |arg|
        if arg.is_a? Symbol
          self.table && self.table[arg] ? Arel::Visitors.for(ActiveRecord::Base).accept(table[arg]) : arg
        else
          arg.table = self.table if arg.is_a? MetaWhere::Function
          Arel::Visitors.for(ActiveRecord::Base).accept(arg)
        end
      end
    end
  end
end

module Arel
  module Visitors
    class ToSql
      def visit_MetaWhere_Function o
        o.to_sqlliteral
      end
    end
  end
end