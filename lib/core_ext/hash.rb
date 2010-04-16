class Hash
  def to_predicate(table)
    builder = ActiveRecord::PredicateBuilder.new(table.engine)
    # Cool, you're using github.com/ernie/arel, or my patches have been merged! :)
    if defined?(Arel::Predicates::All)
      Arel::Predicates::All.new(*builder.build_from_hash(self, table))
    else
      predicates = builder.build_from_hash(self, table)
      compound = predicates.shift
      predicates.inject(compound) do |compound, predicate|
        compound.and(predicate)
      end
    end
  end
  
  def |(other)
    MetaWhere::Or.new(self, other)
  end
  
  def &(other)
    MetaWhere::And.new(self, other)
  end
end