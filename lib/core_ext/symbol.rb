require 'meta_where/predicate_methods'

class Symbol
  # These extensions to Symbol are loaded optionally, with:
  #
  #   MetaWhere.configure do |config|
  #     config.load_core_extensions!
  #   end

  include MetaWhere::PredicateMethods

  def asc
    MetaWhere::Nodes::Order.new self, 1
  end

  def desc
    MetaWhere::Nodes::Order.new self, -1
  end

  def func(*args)
    MetaWhere::Nodes::Function.new(self, args)
  end

  def inner
    MetaWhere::Nodes::Join.new(self, Arel::InnerJoin)
  end

  def outer
    MetaWhere::Nodes::Join.new(self, Arel::OuterJoin)
  end

  def of_class(klass)
    MetaWhere::Nodes::Join.new(self, Arel::InnerJoin, klass)
  end

end