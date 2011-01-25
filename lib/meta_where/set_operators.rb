module MetaWhere
  module SetOperators

    def self.included(base)
      base.class_eval do
        remove_method :&
      end
    end

    def |(other)
      arel.union(other)
    end

    def +(other)
      arel.union(:all, other)
    end

    def &(other)
      arel.intersect(other)
    end

    def -(other)
      arel.except(other)
    end

  end
end
