class Hash
  def to_predicate(builder, parent = nil)
    Arel::Predicates::All.new(*builder.build_predicates_from_hash(self, parent || builder.join_dependency.join_base))
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