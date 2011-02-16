require 'meta_where/visitors/base'
require 'meta_where/contexts/join_dependency_context'

module MetaWhere
  module Visitors
    class OrderVisitor < Base

      def visit_Hash(o, parent)
        k = k.symbol if Nodes::Stub === k
        o.map do |k, v|
          if Hash === v
            accept(v, find(k, parent) || k)
          elsif v.is_a?(Array) && !v.empty? && v.all? {|val| can_accept?(val)}
            new_parent = find(k, parent)
            v.map {|val| accept(val, new_parent || k)}
          else
            can_accept?(v) ? accept(v, find(k, parent) || k) : v
          end
        end.flatten
      end

      def visit_Array(o, parent)
        o.map { |v| can_accept?(v) ? accept(v, parent) : v }.flatten
      end

      def visit_Symbol(o, parent)
        contextualize(parent)[o]
      end

      def visit_MetaWhere_Nodes_Stub(o, parent)
        contextualize(parent)[o.symbol]
      end

      def visit_MetaWhere_Nodes_Order(o, parent)
        contextualize(parent)[o.attribute].send(o.descending? ? :desc : :asc)
      end

    end
  end
end