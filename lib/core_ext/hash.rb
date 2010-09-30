class Hash
  def to_predicate(builder, parent = nil)
    predicates = builder.build_predicates_from_hash(self, parent || builder.join_dependency.join_base)
    if predicates.size > 1
      first = predicates.shift
      Arel::Nodes::Grouping.new(predicates.inject(first) {|memo, expr| Arel::Nodes::And.new(memo, expr)})
    else
      predicates.first
    end
  end

  def to_attribute(builder, parent = nil)
    builder.build_attributes_from_hash(self, parent)
  end

  def |(other)
    MetaWhere::Or.new(self, other)
  end

  def &(other)
    MetaWhere::And.new(self, other)
  end
end