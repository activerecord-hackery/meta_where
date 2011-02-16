require 'meta_where/visitors/base'
require 'meta_where/contexts/join_dependency_context'

module MetaWhere
  module Visitors
    class PredicateVisitor < Base

      def visit_Hash(o, parent)
        predicates = o.map do |k, v|
          k = k.symbol if Nodes::Stub === k
          if Hash === v
            accept(v, find(k, parent) || k)
          elsif v.is_a?(Array) && !v.empty? && v.all? {|val| can_accept?(val)}
            new_parent = find(k, parent)
            v.map {|val| accept(val, new_parent || k)}
          elsif Nodes::Predicate === v
            accept(v, find(k, parent) || k)
          elsif Nodes::Function === v
            attribute = contextualize(parent)[k]
            attribute.eq(accept(v, parent))
          else
            case k
            when Nodes::Predicate
              accept(k % v, parent)
            when Nodes::Function
              [Array, Range, Arel::SelectManager].include?(v.class) ? accept(k, parent).in(v) : accept(k, parent).eq(v)
            else
              attribute = contextualize(parent)[k]
              [Array, Range, Arel::SelectManager].include?(v.class) ? attribute.in(v) : attribute.eq(v)
            end
          end
        end

        predicates.flatten!

        if predicates.size > 1
          Arel::Nodes::Grouping.new(Arel::Nodes::And.new predicates)
        else
          predicates.first
        end
      end

      def visit_Array(o, parent)
        if o.first.is_a? String
          base.send(:sanitize_sql, o)
        else
          o.map { |v| can_accept?(v) ? accept(v, parent) : v }.flatten
        end
      end

      def visit_MetaWhere_Nodes_Predicate(o, parent)
        value = (Nodes::Function === o.value ? accept(o.value, parent) : o.value)
        if Nodes::Function === o.expr
          accept(o.expr, parent).send(o.method_name, value)
        else
          contextualize(parent)[o.expr].send(o.method_name, value)
        end
      end

      def visit_MetaWhere_Nodes_Function(o, parent)
        args = o.args.map do |arg|
          case arg
          when Nodes::Function
            accept(arg, parent)
          when Symbol
            Arel.sql(arel_visitor.accept contextualize(parent)[arg])
          when Nodes::Stub
            Arel.sql(arel_visitor.accept contextualize(parent)[arg.symbol])
          else
            arg
          end
        end
        Arel::Nodes::NamedFunction.new(o.name, args, o.alias)
      end

      def visit_MetaWhere_Nodes_And(o, parent)
        Arel::Nodes::Grouping.new(Arel::Nodes::And.new(accept(o.children, parent)))
      end

      def visit_MetaWhere_Nodes_Or(o, parent)
        accept(o.left, parent).or(accept(o.right, parent))
      end

      def visit_MetaWhere_Nodes_Not(o, parent)
        accept(o.expr, parent).not
      end

    end
  end
end