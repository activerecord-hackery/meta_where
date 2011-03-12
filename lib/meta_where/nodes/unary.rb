require 'meta_where/nodes/predicate_operators'

module MetaWhere
  module Nodes
    class Unary
      include PredicateOperators

      attr_reader :expr

      def initialize(expr)
        @expr = expr
      end

      def eql?(other)
        self.class == other.class &&
        self.expr  == other.expr
      end

      alias :== :eql?
    end
  end
end