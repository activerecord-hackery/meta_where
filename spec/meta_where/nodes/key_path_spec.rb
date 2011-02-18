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

      it 'sends missing calls to its endpoint if the endpoint responds to them' do
        @k.third.fourth.fifth.matches('Joe%')
        @k.endpoint.should be_a Predicate
        @k.endpoint.expr.should eq :fifth
        @k.endpoint.method_name.should eq :matches
        @k.endpoint.value.should eq 'Joe%'
      end

      it 'creates a polymorphic join at its endpoint' do
        @k.third.fourth.fifth(Person)
        @k.endpoint.should be_a Join
        @k.endpoint.should be_polymorphic
      end

      it 'creates a named function at its endpoint' do
        @k.third.fourth.fifth.max(1,2,3)
        @k.endpoint.should be_a Function
        @k.endpoint.name.should eq :max
        @k.endpoint.args.should eq [1,2,3]
      end

    end
  end
end