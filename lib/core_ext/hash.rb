class Hash

  def |(other)
    MetaWhere::Or.new(self, other)
  end

  def &(other)
    MetaWhere::And.new(self, other)
  end
end