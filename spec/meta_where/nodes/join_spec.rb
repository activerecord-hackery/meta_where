require 'spec_helper'

module MetaWhere
  module Nodes
    describe Join do

      it 'defaults to Arel::InnerJoin' do
        @j = Join.new :name
        @j.type.should eq Arel::InnerJoin
      end

      it 'allows setting join type' do
        @j = Join.new :name
        @j.outer
        @j.type.should eq Arel::OuterJoin
      end

    end
  end
end