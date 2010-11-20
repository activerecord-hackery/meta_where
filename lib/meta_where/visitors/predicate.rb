require 'meta_where/visitors/visitor'

module MetaWhere
  module Visitors
    class Predicate < Visitor

      def self.visitables
        [Hash, MetaWhere::Or, MetaWhere::And, MetaWhere::Condition, MetaWhere::Function]
      end

      def visit_Hash(o, parent)
        parent ||= join_dependency.join_base
        table = tables[parent]
        predicates = o.map do |column, value|
          if value.is_a?(Hash)
            association = association_from_parent_and_column(parent, column)
            accept(value, association || column)
          elsif [MetaWhere::Condition, MetaWhere::And, MetaWhere::Or].include?(value.class)
            association = association_from_parent_and_column(parent, column)
            accept(value, association || column)
          elsif value.is_a?(Array) && !value.empty? && value.all? {|v| can_accept?(v)}
            association = association_from_parent_and_column(parent, column)
            value.map {|val| accept(val, association || column)}
          else
            if column.is_a?(MetaWhere::Column)
              method = column.method
              column = column.column
            else
              method = method_from_value(value)
            end

            if [String, Symbol].include?(column.class) && column.to_s.include?('.')
              table_name, column = column.to_s.split('.', 2)
              table = Arel::Table.new(table_name, :engine => parent.arel_engine)
            end

            unless attribute = attribute_from_column_and_table(column, table)
              raise ::ActiveRecord::StatementInvalid, "No attribute named `#{column}` exists for table `#{table.name}`"
            end

            unless valid_comparison_method?(method)
              raise ::ActiveRecord::StatementInvalid, "No comparison method named `#{method}` exists for column `#{column}`"
            end

            attribute.send(method, args_for_predicate(value))
          end
        end

        predicates.flatten!

        if predicates.size > 1
          first = predicates.shift
          Arel::Nodes::Grouping.new(predicates.inject(first) {|memo, expr| Arel::Nodes::And.new(memo, expr)})
        else
          predicates.first
        end
      end

      def visit_MetaWhere_Or(o, parent)
        accept(o.condition1, parent).or(accept(o.condition2, parent))
      end

      def visit_MetaWhere_And(o, parent)
        accept(o.condition1, parent).and(accept(o.condition2, parent))
      end

      def visit_MetaWhere_Condition(o, parent)
        table = tables[parent]

        unless attribute = attribute_from_column_and_table(o.column, table)
          raise ::ActiveRecord::StatementInvalid, "No attribute named `#{o.column}` exists for table `#{table.name}`"
        end

        unless valid_comparison_method?(o.method)
          raise ::ActiveRecord::StatementInvalid, "No comparison method named `#{o.method}` exists for column `#{o.column}`"
        end
        attribute.send(o.method, args_for_predicate(o.value))
      end

      def visit_MetaWhere_Function(o, parent)
        self.table = tables[parent]

        o.to_sqlliteral
      end

    end
  end
end