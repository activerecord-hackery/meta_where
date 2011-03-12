require 'spec_helper'

module MetaWhere
  module Nodes
    describe Operators do

      [:+, :-, :*, :/].each do |operator|
        describe "#{operator}" do
          it "creates Operations with #{operator} operator from stubs" do
            left = Stub.new(:stubby_mcstubbenstein)
            node = left.send(operator, 1)
            node.should be_an Operation
            node.left.should eq left
            node.operator.should eq operator
            node.right.should eq 1
          end

          it "creates Operations with #{operator} operator from key paths" do
            left = KeyPath.new(:first, :second)
            node = left.send(operator, 1)
            node.should be_an Operation
            node.left.should eq left
            node.operator.should eq operator
            node.right.should eq 1
          end

          it "creates Operations with #{operator} operator from functions" do
            left = Function.new(:name, ["arg1", "arg2"])
            node = left.send(operator, 1)
            node.should be_an Operation
            node.left.should eq left
            node.operator.should eq operator
            node.right.should eq 1
          end

          it "creates Operations with #{operator} operator from operations" do
            left = Stub.new(:stubby_mcstubbenstein) + 1
            node = left.send(operator, 1)
            node.should be_an Operation
            node.left.should eq left
            node.operator.should eq operator
            node.right.should eq 1
          end
        end
      end

    end
  end
end