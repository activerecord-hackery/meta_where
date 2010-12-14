module MetaWhere
  module Utility
    private

    def array_of_activerecords(val)
      val.is_a?(Array) && !val.empty? && val.all? {|v| v.is_a?(ActiveRecord::Base)}
    end

    def association_from_parent_and_column(parent, column)
      parent.is_a?(Symbol) ? nil : @join_dependency.send(:find_join_association, column, parent)
    end

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
      when Array, ActiveRecord::Associations::AssociationCollection, ActiveRecord::Relation
        value.to_a.map { |x|
          x.respond_to?(:quoted_id) ? x.quoted_id : x
        }
      when ActiveRecord::Base
        value.quoted_id
      else
        value
      end
    end

    def method_from_value(value)
      case value
      when Array, Range, ActiveRecord::Associations::AssociationCollection, ActiveRecord::Relation, Arel::Relation
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