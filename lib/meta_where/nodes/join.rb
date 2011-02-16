module MetaWhere
  module Nodes
    class Join
      attr_reader :name, :type, :klass

      def initialize(name, type = Arel::InnerJoin)
        @name, @type = name, type
      end

      def inner
        @type = Arel::InnerJoin
        self
      end

      def outer
        @type = Arel::OuterJoin
        self
      end

    end
  end
end