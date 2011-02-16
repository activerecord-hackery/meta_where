require 'spec_helper'

describe Symbol do

  MetaWhere::PREDICATES.each do |method_name|
    it "creates #{method_name} predicates with no value" do
      predicate = :attribute.send(method_name)
      predicate.expr.should eq :attribute
      predicate.method_name.should eq method_name
      predicate.value?.should be_false
    end

    it "creates #{method_name} predicates with a value" do
      predicate = :attribute.send(method_name, 'value')
      predicate.expr.should eq :attribute
      predicate.method_name.should eq method_name
      predicate.value.should eq 'value'
    end
  end

  it 'creates ascending orders' do
    order = :attribute.asc
    order.should be_ascending
  end

  it 'creates descending orders' do
    order = :attribute.desc
    order.should be_descending
  end

  it 'creates functions' do
    function = :function.func
    function.should be_a MetaWhere::Nodes::Function
  end

  it 'creates inner joins' do
    join = :join.inner
    join.should be_a MetaWhere::Nodes::Join
    join.type.should eq Arel::InnerJoin
  end

  it 'creates outer joins' do
    join = :join.outer
    join.should be_a MetaWhere::Nodes::Join
    join.type.should eq Arel::OuterJoin
  end

end