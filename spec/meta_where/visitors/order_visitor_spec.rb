module MetaWhere
  module Visitors
    describe OrderVisitor do

      before do
        @jd = ActiveRecord::Associations::ClassMethods::JoinDependency.
             new(Person, {
               :children => {
                 :children => {
                   :parent => :parent
                 }
               }
             }, [])
        @c = MetaWhere::Contexts::JoinDependencyContext.new(@jd)
        @v = OrderVisitor.new(@c)
      end

      it 'creates a bare ARel attribute given a symbol with no asc/desc' do
        attribute = @v.accept(:name)
        attribute.should be_a Arel::Attribute
        attribute.name.should eq :name
        attribute.relation.name.should eq 'people'
      end

      it 'creates the ordering against the proper table for nested hashes' do
        orders = @v.accept({
          :children => {
            :children => {
              :parent => {
                :parent => :name.asc
              }
            }
          }
        })
        orders.should be_a Array
        ordering = orders.first
        ordering.should be_a Arel::Nodes::Ordering
        ordering.expr.relation.table_alias.should eq 'parents_people_2'
        ordering.direction.should eq :asc
      end

      it 'will not alter values it is unable to accept' do
        orders = @v.accept(['THIS PARAMETER', 'WHAT DOES IT MEAN???'])
        orders.should eq ['THIS PARAMETER', 'WHAT DOES IT MEAN???']
      end

      it 'treats keypath keys like nested hashes' do
        ordering = @v.accept(Nodes::Stub.new(:children).children.parent.parent.name.asc)
        ordering.should be_a Arel::Nodes::Ordering
        ordering.expr.relation.table_alias.should eq 'parents_people_2'
        ordering.direction.should eq :asc
      end

      it 'allows hashes inside keypath keys' do
        orders = @v.accept(Nodes::Stub.new(:children).children.parent.parent => :name.asc)
        orders.should be_a Array
        ordering = orders.first
        ordering.should be_a Arel::Nodes::Ordering
        ordering.expr.relation.table_alias.should eq 'parents_people_2'
        ordering.direction.should eq :asc
      end

    end
  end
end