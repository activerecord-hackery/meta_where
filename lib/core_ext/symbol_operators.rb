class Symbol
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

  # Won't work on Ruby 1.8.x so need to do this conditionally
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