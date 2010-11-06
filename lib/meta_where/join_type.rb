module MetaWhere
  class JoinType
    attr_reader :name, :join_type

    def initialize(name, join_type = Arel::Nodes::InnerJoin)
      @name = name
      @join_type = join_type
    end

    def ==(other)
      self.class == other.class &&
      name == other.name &&
      join_type == other.join_type
    end

    alias_method :eql?, :==

    def hash
      [name, join_type].hash
    end
  end
end