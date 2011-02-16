require 'spec_helper'

module MetaWhere
  describe DSL do

    it 'evaluates code' do
      result = DSL.evaluate { {id => 1} }
      result.should be_a Hash
      result.keys.first.should be_a Nodes::Stub
    end

    it 'creates function nodes when a method has arguments' do
      result = DSL.evaluate { max(id) }
      result.should be_a Nodes::Function
      result.args.should eq [Nodes::Stub.new(:id)]
    end

    it 'creates polymorphic join nodes when a method has a single class argument' do
      result = DSL.evaluate { association(Person) }
      result.should be_a Nodes::Join
      result.klass.should eq Person
    end

  end
end