class Symbol
  Arel::Attribute::Predications.instance_methods.each do |predication|
    define_method(predication) do
      MetaWhere::Column.new(self, predication)
    end
  end
  
  MetaWhere::METHOD_ALIASES.each_pair do |aliased, predication|
    define_method(aliased) do
      MetaWhere::Column.new(self, predication)
    end
  end
  
  def [](value)
    MetaWhere::Condition.new(self, value, :eq)
  end
  
  def ^(value)
    MetaWhere::Condition.new(self, value, :not_eq)
  end
  
  def +(value)
    MetaWhere::Condition.new(self, value, :in)
  end
  
  def -(value)
    MetaWhere::Condition.new(self, value, :not_in)
  end
  
  def =~(value)
    MetaWhere::Condition.new(self, value, :matches)
  end
  
  if respond_to?('!~')
    define_method('!~') do |value|
      MetaWhere::Condition.new(self, value, :not_matches)
    end
  end
  
  def >(value)
    MetaWhere::Condition.new(self, value, :gt)
  end
  
  def >=(value)
    MetaWhere::Condition.new(self, value, :gteq)
  end
  
  def <(value)
    MetaWhere::Condition.new(self, value, :lt)
  end
  
  def <=(value)
    MetaWhere::Condition.new(self, value, :lteq)
  end
end