class Symbol
  def [](method)
    MetaWhere::Column.new(self, method)
  end
  
  def ^(value)
    MetaWhere::Condition.new(self, value, :noteq)
  end
  
  def +(value)
    MetaWhere::Condition.new(self, value, :in)
  end
  
  def -(value)
    MetaWhere::Condition.new(self, value, :notin)
  end

  def =~(value)
    MetaWhere::Condition.new(self, value, :matches)
  end
  
  if respond_to?('!~')
    define_method('!~') do |value|
      MetaWhere::Condition.new(self, value, :notmatches)
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