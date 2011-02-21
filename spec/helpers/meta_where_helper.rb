module MetaWhereHelper
  def dsl(&block)
    MetaWhere::DSL.evaluate(&block)
  end
end