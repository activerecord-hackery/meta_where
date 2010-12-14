class Symbol
  MetaWhere::PREDICATES.each do |predication|
    define_method(predication) do
      MetaWhere::Column.new(self, predication)
    end
  end

  MetaWhere::METHOD_ALIASES.each_pair do |aliased, predication|
    define_method(aliased) do
      MetaWhere::Column.new(self, predication)
    end
  end

  def mw_func(*args)
    MetaWhere::Function.new(self, *args)
  end

  alias_method :func, :mw_func unless method_defined?(:func)

  def inner
    MetaWhere::JoinType.new(self, Arel::Nodes::InnerJoin)
  end

  def outer
    MetaWhere::JoinType.new(self, Arel::Nodes::OuterJoin)
  end

  def type(klass)
    MetaWhere::JoinType.new(self, Arel::Nodes::InnerJoin, klass)
  end

  def asc
    MetaWhere::Column.new(self, :asc)
  end

  def desc
    MetaWhere::Column.new(self, :desc)
  end
end