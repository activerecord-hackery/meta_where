require 'spec_helper'

module MetaWhere
  module Nodes
    describe Predicate do

      context 'ARel predicate methods' do
        before do
          @p = Predicate.new(:attribute)
        end

        MetaWhere::PREDICATES.each do |method_name|
          it "creates #{method_name} predicates with no value" do
            predicate = @p.send(method_name)
            predicate.expr.should eq :attribute
            predicate.method_name.should eq method_name
            predicate.value?.should be_false
          end

          it "creates #{method_name} predicates with a value" do
            predicate = @p.send(method_name, 'value')
            predicate.expr.should eq :attribute
            predicate.method_name.should eq method_name
            predicate.value.should eq 'value'
          end
        end
      end

      it 'accepts a value on instantiation' do
        @p = Predicate.new :name, :eq, 'value'
        @p.value.should eq 'value'
      end

      it 'sets value via accessor' do
        @p = Predicate.new :name, :eq
        @p.value = 'value'
        @p.value.should eq 'value'
      end

      it 'sets value via %' do
        @p = Predicate.new :name, :eq
        @p % 'value'
        @p.value.should eq 'value'
      end

      it 'can be inquired for value presence' do
        @p = Predicate.new :name, :eq
        @p.value?.should be_false
        @p.value = 'value'
        @p.value?.should be_true
      end

    end
  end
end