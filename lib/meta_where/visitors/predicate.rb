module MetaWhere
  module Visitors
    module Predicate

      def predicate_visit_Hash(o, parent)
        predicates = self.build_predicates_from_hash(o, parent || self.join_dependency.join_base)
        if predicates.size > 1
          first = predicates.shift
          Arel::Nodes::Grouping.new(predicates.inject(first) {|memo, expr| Arel::Nodes::And.new(memo, expr)})
        else
          predicates.first
        end
      end

      def predicate_visit_MetaWhere_Or(o, parent)
        predicate_accept(o.condition1, parent).or(predicate_accept(o.condition2, parent))
      end

      def predicate_visit_MetaWhere_And(o, parent)
        predicate_accept(o.condition1, parent).and(predicate_accept(o.condition2, parent))
      end

      def predicate_visit_MetaWhere_Condition(o, parent)
        table = self.build_table(parent)

        unless attribute = attribute_from_column_and_table(o.column, table)
          raise ::ActiveRecord::StatementInvalid, "No attribute named `#{o.column}` exists for table `#{table.name}`"
        end

        unless valid_comparison_method?(o.method)
          raise ::ActiveRecord::StatementInvalid, "No comparison method named `#{o.method}` exists for column `#{o.column}`"
        end
        attribute.send(o.method, args_for_predicate(o.value))
      end

      def predicate_visit_MetaWhere_Function(o, parent)
        self.table = self.build_table(parent)

        o.to_sqlliteral
      end

      def predicate_accept(object, parent = nil)
        predicate_visit(object, parent)
      end

      def can_predicate?(object)
        respond_to? PRED_DISPATCH[object.class]
      end

      private

      PRED_DISPATCH = Hash.new do |hash, klass|
        hash[klass] = "predicate_visit_#{klass.name.gsub('::', '_')}"
      end

      def predicate_visit(object, parent)
        send(PRED_DISPATCH[object.class], object, parent)
      end

    end
  end
end