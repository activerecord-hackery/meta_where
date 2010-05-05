class Hash
  def to_predicate(builder, parent = nil)
    Arel::Predicates::All.new(*builder.build_from_hash(self, parent))
  end
  
  def |(other)
    MetaWhere::Or.new(self, other)
  end
  
  def &(other)
    MetaWhere::And.new(self, other)
  end
end