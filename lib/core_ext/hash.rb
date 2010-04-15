class Hash
  def to_predicate(table)
    builder = ActiveRecord::PredicateBuilder.new(table.engine)
    builder.build_from_hash(self, table)
  end
  
  def |(other)
    MetaWhere::Or.new(self, other)
  end
  
  def &(other)
    MetaWhere::And.new(self, other)
  end
end