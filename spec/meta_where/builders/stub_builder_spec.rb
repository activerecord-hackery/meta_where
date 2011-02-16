require 'spec_helper'

module MetaWhere
  module Builders
    describe StubBuilder do

      it 'evaluates code' do
        result = StubBuilder.build { {id => 1} }
        result.should be_a Hash
        result.keys.first.should be_a Nodes::Stub
      end

    end
  end
end