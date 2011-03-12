require 'meta_where/nodes/predicate_operators'

module MetaWhere
  module Nodes
    class Binary
      include PredicateOperators

      attr_reader :left, :right

      def initialize(left, right)
        @left, @right = left, right
      end

      def eql?(other)
        self.class == other.class &&
        self.left  == other.left &&
        self.right == other.right
      end

      alias :== :eql?
    end
  end
end