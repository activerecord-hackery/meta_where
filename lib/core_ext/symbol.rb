class Symbol
  def [](method)
    MetaWhere::Column.new(self, method)
  end
end