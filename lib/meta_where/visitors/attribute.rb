require 'meta_where/visitors/visitor'

module MetaWhere
  module Visitors
    class Attribute < Visitor

      def self.visitables
        [Hash, Symbol, MetaWhere::Column]
      end

      def visit_Hash(o, parent)
        parent = parent.name if parent.is_a? MetaWhere::JoinType
        table = tables[parent]
        built_attributes = o.map do |column, value|
          if value.is_a?(Hash)
            association = association_from_parent_and_column(parent, column)
            accept(value, association || column)
          elsif value.is_a?(Array) && value.all? {|v| can_accept?(v)}
            association = association_from_parent_and_column(parent, column)
            value.map {|val| self.accept(val, association || column)}
          else
            association = association_from_parent_and_column(parent, column)
            can_accept?(value) ? self.accept(value, association || column) : value
          end
        end

        built_attributes.flatten
      end

      def visit_Symbol(o, parent)
        table = tables[parent]

        unless attribute = table[o]
          raise ::ActiveRecord::StatementInvalid, "No attribute named `#{o}` exists for table `#{table.name}`"
        end

        attribute
      end

      def visit_MetaWhere_Column(o, parent)
        column_name = o.column.to_s
        if column_name.include?('.')
          table_name, column_name = column_name.split('.', 2)
          table = Arel::Table.new(table_name, :engine => parent.arel_engine)
        else
          table = tables[parent]
        end

        unless attribute = table[column_name]
          raise ::ActiveRecord::StatementInvalid, "No attribute named `#{column_name}` exists for table `#{table.name}`"
        end

        attribute.send(o.method)
      end

    end
  end
end