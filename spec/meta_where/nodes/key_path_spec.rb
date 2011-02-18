module MetaWhere
  module Nodes
    describe KeyPath do
      before do
        @k = KeyPath.new(:first, :second)
      end

      it 'appends to its path when endpoint is a Stub' do
        @k.third.fourth.fifth
        @k.path.should eq [:first, :second, :third, :fourth]
        @k.endpoint.should eq Stub.new(:fifth)
      end

      it 'stops appending once its endpoint is not a Stub' do
        @k.third.fourth.fifth == 'cinco'
        @k.endpoint.should eq Predicate.new(:fifth, :eq, 'cinco')
        expect { @k.another }.to raise_error NoMethodError
      end

    end
  end
end