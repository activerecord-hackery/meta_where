class Symbol

  MetaWhere::PREDICATES.each do |method_name|
    class_eval <<-RUBY
      def #{method_name}(value = :__undefined__)
        MetaWhere::Nodes::Predicate.new self, :#{method_name}, value
      end
    RUBY
  end

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