module MetaWhere
  module Visitors
    describe SelectVisitor do

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
        @v = SelectVisitor.new(@c)
      end

      it 'creates a bare ARel attribute given a symbol with no asc/desc' do
        attribute = @v.accept(:name)
        attribute.should be_a Arel::Attribute
        attribute.name.should eq :name
        attribute.relation.name.should eq 'people'
      end

      it 'creates the select against the proper table for nested hashes' do
        selects = @v.accept({
          :children => {
            :children => {
              :parent => {
                :parent => :name
              }
            }
          }
        })
        selects.should be_a Array
        select = selects.first
        select.should be_a Arel::Attribute
        select.relation.table_alias.should eq 'parents_people_2'
      end

      it 'will not alter values it is unable to accept' do
        select = @v.accept(['THIS PARAMETER', 'WHAT DOES IT MEAN???'])
        select.should eq ['THIS PARAMETER', 'WHAT DOES IT MEAN???']
      end

      it 'treats keypath keys like nested hashes' do
        select = @v.accept(Nodes::Stub.new(:children).children.parent.parent.name)
        select.should be_a Arel::Attribute
        select.relation.table_alias.should eq 'parents_people_2'
      end

      it 'allows hashes inside keypath keys' do
        selects = @v.accept(Nodes::Stub.new(:children).children.parent.parent => :name)
        selects.should be_a Array
        select = selects.first
        select.should be_a Arel::Attribute
        select.relation.table_alias.should eq 'parents_people_2'
      end

    end
  end
end