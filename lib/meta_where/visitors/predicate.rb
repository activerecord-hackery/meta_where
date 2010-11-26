require 'meta_where/visitors/visitor'

module MetaWhere
  module Visitors
    class Predicate < Visitor

      def self.visitables
        [Hash, Array, MetaWhere::Or, MetaWhere::And, MetaWhere::Condition, MetaWhere::Function]
      end

      def visit_Hash(o, parent)
        parent ||= join_dependency.join_base
        parent = parent.name if parent.is_a? MetaWhere::JoinType
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
          elsif (value.is_a?(ActiveRecord::Base) || array_of_activerecords(value)) &&
              reflection = parent.active_record.reflect_on_association(column.is_a?(MetaWhere::JoinType) ? column.name : column)
            accept_activerecord_values(column, value, parent, reflection)
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

            unless valid_comparison_method?(method)
              raise ::ActiveRecord::StatementInvalid, "No comparison method named `#{method}` exists for column `#{column}`"
            end

            if attribute = attribute_from_column_and_table(column, table)
              attribute.send(method, args_for_predicate(value))
            else
              raise ::ActiveRecord::StatementInvalid, "No attribute named `#{column}` exists for table `#{table.name}`"
            end

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

      def visit_Array(o, parent)
        if o.first.is_a? String
          join_dependency.join_base.send(:sanitize_sql, o)
        else
          o.map {|e| accept(e, parent)}.flatten
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

      private

      def accept_activerecord_values(column, value, parent, reflection)
        groups = Array.wrap(value).group_by {|v| v.class.base_class}
        unless reflection.options[:polymorphic] || groups.keys.all? {|k| reflection.klass == k}
          raise ArgumentError, "An object you supplied to :#{reflection.name} is not a #{reflection.klass}!"
        end
        case reflection.macro
        when :has_many, :has_one, :has_and_belongs_to_many
          conditions = nil
          groups.each do |klass, values|
            condition = {
              (reflection.options[:foreign_key] || reflection.klass.primary_key).to_sym => values.size == 1 ? values.first.id : values.map(&:id)
            }
            conditions = conditions ? conditions | condition : condition
          end

          accept(conditions, association_from_parent_and_column(parent, column) || column)
        when :belongs_to
          conditions = nil
          groups.each do |klass, values|
            condition = if reflection.options[:polymorphic]
              {
                (reflection.options[:foreign_key] || reflection.primary_key_name).to_sym => values.size == 1 ? values.first.id : values.map(&:id),
                reflection.options[:foreign_type].to_sym => klass.name
              }
            else
              {(reflection.options[:foreign_key] || reflection.primary_key_name).to_sym => values.size == 1 ? values.first.id : values.map(&:id)}
            end
            conditions = conditions ? conditions | condition : condition
          end

          accept(conditions, parent)
        end
      end

      def sanitize_or_accept_reflection_conditions(reflection, parent, column)
        if !can_accept?(reflection.options[:conditions])
          reflection.sanitized_conditions
        else
          accept(reflection.options[:conditions], association_from_parent_and_column(parent, column) || column)
        end
      end

    end
  end
end