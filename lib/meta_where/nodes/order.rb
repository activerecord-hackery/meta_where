module MetaWhere
  module Nodes
    class Order
      attr_reader :attribute, :direction

      def initialize(attribute, direction = 1)
        raise ArgumentError, "Direction #{direction} is not valid. Must be -1 or 1." unless [-1,1].include? direction
        @attribute, @direction = attribute, direction
      end

      def asc
        @direction = 1
        self
      end

      def desc
        @direction = -1
        self
      end

      def ascending?
        @direction == 1
      end

      def descending?
        @direction == -1
      end

      def reverse!
        @direction = - @direction
        self
      end
    end
  end
end