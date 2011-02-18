require 'spec_helper'

module MetaWhere
  module Visitors
    describe PredicateVisitor do

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
        @v = PredicateVisitor.new(@c)
      end

      it 'creates Equality nodes for simple hashes' do
        predicate = @v.accept(:name => 'Joe')
        predicate.should be_a Arel::Nodes::Equality
        predicate.left.name.should eq :name
        predicate.right.should eq 'Joe'
      end

      it 'creates In nodes for simple hashes with an array as a value' do
        predicate = @v.accept(:name => ['Joe', 'Bob'])
        predicate.should be_a Arel::Nodes::In
        predicate.left.name.should eq :name
        predicate.right.should eq ['Joe', 'Bob']
      end

      it 'creates the node against the proper table for nested hashes' do
        predicate = @v.accept({
          :children => {
            :children => {
              :parent => {
                :parent => {
                  :name => 'Joe'
                }
              }
            }
          }
        })
        predicate.should be_a Arel::Nodes::Equality
        predicate.left.relation.table_alias.should eq 'parents_people_2'
        predicate.right.should eq 'Joe'
      end

      it 'treats keypath keys like nested hashes' do
        standard = @v.accept({
          :children => {
            :children => {
              :parent => {
                :parent => {
                  :name => 'Joe'
                }
              }
            }
          }
        })
        keypath = @v.accept(Nodes::Stub.new(:children).children.parent.parent.name => 'Joe')
        keypath.to_sql.should eq standard.to_sql
      end

      it 'allows hashes inside keypath keys' do
        standard = @v.accept({
          :children => {
            :children => {
              :parent => {
                :parent => {
                  :name => 'Joe'
                }
              }
            }
          }
        })
        keypath = @v.accept(Nodes::Stub.new(:children).children.parent.parent => {:name => 'Joe'})
        keypath.to_sql.should eq standard.to_sql
      end

      it 'creates a node of the proper type when a hash has a Predicate as a key' do
        predicate = @v.accept(:name.matches => 'Joe%')
        predicate.should be_a Arel::Nodes::Matches
        predicate.left.name.should eq :name
        predicate.right.should eq 'Joe%'
      end

      it 'treats hash keys as an association when there is an array of "acceptables" on the value side' do
        predicate = @v.accept(:children => [:name.matches % 'Joe%', :name.eq % 'Bob'])
        predicate.should be_a Arel::Nodes::Grouping
        predicate.expr.should be_a Arel::Nodes::And
        predicate.expr.children.should have(2).items
        predicate.expr.children.first.should be_a Arel::Nodes::Matches
        predicate.expr.children.first.left.relation.table_alias.should eq 'children_people'
      end

      it 'creates an ARel Grouping node containing an And node for And nodes' do
        left = :name.matches % 'Joe%'
        right = :id.gt % 1
        predicate = @v.accept(left - right)
        predicate.should be_a Arel::Nodes::Grouping
        predicate.expr.should be_a Arel::Nodes::And
        predicate.expr.children.should have(2).items
      end

      it 'creates an ARel Grouping node containing an Or node for Or nodes' do
        left = :name.matches % 'Joe%'
        right = :id.gt % 1
        predicate = @v.accept(left | right)
        predicate.should be_a Arel::Nodes::Grouping
        predicate.expr.should be_a Arel::Nodes::Or
        predicate.expr.left.should be_a Arel::Nodes::Matches
        predicate.expr.right.should be_a Arel::Nodes::GreaterThan
      end

      it 'creates an ARel Not node for a Not node' do
        expr = -(:name.matches % 'Joe%')
        predicate = @v.accept(expr)
        predicate.should be_a Arel::Nodes::Not
      end

      it 'creates an ARel NamedFunction node for a Function node' do
        function = @v.accept(:find_in_set.func())
        function.should be_a Arel::Nodes::NamedFunction
      end

      it 'maps symbols in Function args to ARel attributes' do
        function = @v.accept(:find_in_set.func(:id, '1,2,3'))
        function.to_sql.should match /"people"."id"/
      end

      it 'sets the alias on the ARel NamedFunction from the Function alias' do
        function = @v.accept(:find_in_set.func(:id, '1,2,3').as('newname'))
        function.to_sql.should match /newname/
      end

    end
  end
end