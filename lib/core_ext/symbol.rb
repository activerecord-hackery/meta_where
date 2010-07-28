class Symbol
  Arel::Attribute::PREDICATES.each do |predication|
    define_method(predication) do
      MetaWhere::Column.new(self, predication)
    end
  end
  
  MetaWhere::METHOD_ALIASES.each_pair do |aliased, predication|
    define_method(aliased) do
      MetaWhere::Column.new(self, predication)
    end
  end
  
  def to_attribute(builder, parent = nil)
    table = builder.build_table(parent)
    
    unless attribute = table[self]
      raise ::ActiveRecord::StatementInvalid, "No attribute named `#{self}` exists for table `#{table.name}`"
    end

    attribute
  end
  
  def asc
    MetaWhere::Column.new(self, :asc)
  end
  
  def desc
    MetaWhere::Column.new(self, :desc)
  end
end