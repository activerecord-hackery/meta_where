module MetaWhere
  module Nodes
    module Operators

      def +(value)
        Operation.new(self, :+, value)
      end

      def -(value)
        Operation.new(self, :-, value)
      end

      def *(value)
        Operation.new(self, :*, value)
      end

      def /(value)
        Operation.new(self, :/, value)
      end

    end
  end
end