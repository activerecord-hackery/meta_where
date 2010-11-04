module MetaWhere
  module Visitors
    module Attribute

      def attribute_visit_Hash(o, parent)
        self.build_attributes_from_hash(o, parent)
      end

      def attribute_visit_Symbol(o, parent)
        table = self.build_table(parent)

        unless attribute = table[o]
          raise ::ActiveRecord::StatementInvalid, "No attribute named `#{o}` exists for table `#{table.name}`"
        end

        attribute
      end

      def attribute_visit_MetaWhere_Column(o, parent)
        column_name = o.column.to_s
        if column_name.include?('.')
          table_name, column_name = column_name.split('.', 2)
          table = Arel::Table.new(table_name, :engine => parent.arel_engine)
        else
          table = self.build_table(parent)
        end

        unless attribute = table[column_name]
          raise ::ActiveRecord::StatementInvalid, "No attribute named `#{column_name}` exists for table `#{table.name}`"
        end

        attribute.send(o.method)
      end

      def attribute_visit_MetaWhere_Or(o, parent)
        attribute_accept(o.condition1, parent).or(attribute_accept(o.condition2, parent))
      end

      def attribute_visit_MetaWhere_And(o, parent)
        attribute_accept(o.condition1, parent).and(attribute_accept(o.condition2, parent))
      end

      def attribute_visit_MetaWhere_Condition(o, parent)
        table = self.build_table(parent)

        unless attribute = attribute_from_column_and_table(o.column, table)
          raise ::ActiveRecord::StatementInvalid, "No attribute named `#{o.column}` exists for table `#{table.name}`"
        end

        unless valid_comparison_method?(o.method)
          raise ::ActiveRecord::StatementInvalid, "No comparison method named `#{o.method}` exists for column `#{o.column}`"
        end
        attribute.send(o.method, args_for_predicate(o.value))
      end

      def attribute_visit_MetaWhere_Function(o, parent)
        o.table = self.build_table(parent)

        o.to_sqlliteral
      end

      def attribute_accept(object, parent = nil)
        attribute_visit(object, parent)
      end

      def can_attribute?(object)
        respond_to? ATTR_DISPATCH[object.class]
      end

      private

      ATTR_DISPATCH = Hash.new do |hash, klass|
        hash[klass] = "attribute_visit_#{klass.name.gsub('::', '_')}"
      end

      def attribute_visit(object, parent)
        send(ATTR_DISPATCH[object.class], object, parent)
      end

    end
  end
end