require 'meta_where/visitors/base'
require 'meta_where/contexts/join_dependency_context'

module MetaWhere
  module Visitors
    class PredicateVisitor < Base

      def visit_Hash(o, parent)
        predicates = o.map do |k, v|
          if implies_context_change?(v)
            visit_with_context_change(k, v, parent)
          else
            visit_without_context_change(k, v, parent)
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
          sanitize_sql(o, parent)
        else
          o.map { |v| can_accept?(v) ? accept(v, parent) : v }.flatten
        end
      end

      def visit_MetaWhere_Nodes_KeyPath(o, parent)
        parent = traverse(o.path, parent)

        accept(o.endpoint, parent)
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

      def implies_context_change?(v)
        case v
        when Hash, Nodes::KeyPath, Nodes::Predicate, Nodes::Unary, Nodes::Binary, Nodes::Nary
          true
        when Array
          (!v.empty? && v.all? {|val| can_accept?(val)})
        else
          false
        end
      end

      def visit_with_context_change(k, v, parent)
        parent = case k
          when Nodes::KeyPath
            traverse(k.path_with_endpoint, parent)
          else
            find(k, parent)
          end

        case v
        when Hash, Nodes::KeyPath, Nodes::Predicate, Nodes::Unary, Nodes::Binary, Nodes::Nary
          accept(v, parent || k)
        when Array
          v.map {|val| accept(val, parent || k)}
        else
          raise ArgumentError, <<-END
          Hashes, Predicates, and arrays of visitables as values imply that their
          corresponding keys are a parent. This didn't work out so well in the case
          of key = #{k} and value = #{v}"
          END
        end
      end

      def visit_without_context_change(k, v, parent)
        v = contextualize(parent)[v.to_sym] if [Nodes::Stub, Symbol].include? v.class
        case k
        when Nodes::Predicate
          accept(k % v, parent)
        when Nodes::Function
          arel_predicate_for(accept(k, parent), v, parent)
        when Nodes::KeyPath
          accept(k % v, parent)
        else
          attribute = contextualize(parent)[k.to_sym]
          arel_predicate_for(attribute, v, parent)
        end
      end

      def arel_predicate_for(attribute, value, parent)
        if [Array, Range, Arel::SelectManager].include?(value.class)
          attribute.in(value)
        else
          value = can_accept?(value) ? accept(value, parent) : value
          attribute.eq(value)
        end
      end

    end
  end
end