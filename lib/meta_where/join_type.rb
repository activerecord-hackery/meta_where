module MetaWhere
  class JoinType
    attr_reader :name, :join_type, :klass

    def initialize(name, join_type = Arel::Nodes::InnerJoin, klass = nil)
      @name = name
      @join_type = join_type
      @klass = klass
    end

    def ==(other)
      self.class == other.class &&
      name == other.name &&
      join_type == other.join_type &&
      klass == other.klass
    end

    alias_method :eql?, :==

    def hash
      [name, join_type, klass].hash
    end

    def outer
      @join_type = Arel::Nodes::OuterJoin
      self
    end

    def inner
      @join_type = Arel::Nodes::InnerJoin
      self
    end

    def type(klass)
      @klass = klass
      self
    end

    def to_sym
      self
    end
  end
end