require 'meta_where/nodes/operators'

module MetaWhere
  module Nodes
    class Unary
      include Operators

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