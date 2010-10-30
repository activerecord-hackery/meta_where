module MetaWhere
  module Utility
    private

    def attribute_from_column_and_table(column, table)
      case column
      when String, Symbol
        table[column]
      when MetaWhere::Function
        column.table = table
        column.to_sqlliteral
      else
        nil
      end
    end

    def args_for_predicate(value)
      case value
      when ActiveRecord::Associations::AssociationCollection, ActiveRecord::Relation
        value.to_a
      else
        value
      end
    end

    def method_from_value(value)
      case value
      when Array, Range, ActiveRecord::Associations::AssociationCollection, ActiveRecord::Relation
        :in
      else
        :eq
      end
    end

    def valid_comparison_method?(method)
      MetaWhere::PREDICATES.map(&:to_s).include?(method.to_s)
    end
  end
end