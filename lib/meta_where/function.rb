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

    def to_predicate(builder, parent = nil)
      self.table = builder.build_table(parent)

      to_sqlliteral
    end

    def to_sqlliteral
      Arel.sql(
        ("#{name}(#{(['%s'] * args.size).join(',')})" % contextualize_args) +
        (self.alias ? " AS #{Arel.sql(self.alias.to_s)}" : '')
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
        MetaWhere::Condition.new(self, value, :not_matches)
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
        case arg
        when Symbol
          self.table && self.table[arg] ? Arel::Visitors.for(table.engine).accept(table[arg]) : arg
        when MetaWhere::Function
          arg.table = self.table
          arg.to_sqlliteral
        when Arel::Nodes::SqlLiteral
          arg
        when String
          ActiveRecord::Base.quote_value arg
        else
          arg
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