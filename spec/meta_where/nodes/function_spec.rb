module MetaWhere
  module Nodes
    describe Function do
      before do
        @f = :function.func(1,2,3)
      end

      MetaWhere::PREDICATES.each do |method_name|
        it "creates #{method_name} predicates with no value" do
          predicate = @f.send(method_name)
          predicate.expr.should eq @f
          predicate.method_name.should eq method_name
          predicate.value?.should be_false
        end

        it "creates #{method_name} predicates with a value" do
          predicate = @f.send(method_name, 'value')
          predicate.expr.should eq @f
          predicate.method_name.should eq method_name
          predicate.value.should eq 'value'
        end
      end

      it 'creates eq predicates with >>' do
        predicate = @f >> 1
        predicate.expr.should eq @f
        predicate.method_name.should eq :eq
        predicate.value.should eq 1
      end

      it 'creates not_eq predicates with ^' do
        predicate = @f ^ 1
        predicate.expr.should eq @f
        predicate.method_name.should eq :not_eq
        predicate.value.should eq 1
      end

      it 'creates in predicates with +' do
        predicate = @f + [1,2,3]
        predicate.expr.should eq @f
        predicate.method_name.should eq :in
        predicate.value.should eq [1,2,3]
      end

      it 'creates not_in predicates with -' do
        predicate = @f - [1,2,3]
        predicate.expr.should eq @f
        predicate.method_name.should eq :not_in
        predicate.value.should eq [1,2,3]
      end

      it 'creates matches predicates with =~' do
        predicate = @f =~ '%bob%'
        predicate.expr.should eq @f
        predicate.method_name.should eq :matches
        predicate.value.should eq '%bob%'
      end

      it 'creates does_not_match predicates with !~' do
        predicate = @f =~ '%bob%'
        predicate.expr.should eq @f
        predicate.method_name.should eq :matches
        predicate.value.should eq '%bob%'
      end

      it 'creates gt predicates with >' do
        predicate = @f > 1
        predicate.expr.should eq @f
        predicate.method_name.should eq :gt
        predicate.value.should eq 1
      end

      it 'creates gteq predicates with >=' do
        predicate = @f >= 1
        predicate.expr.should eq @f
        predicate.method_name.should eq :gteq
        predicate.value.should eq 1
      end

      it 'creates lt predicates with <' do
        predicate = @f < 1
        predicate.expr.should eq @f
        predicate.method_name.should eq :lt
        predicate.value.should eq 1
      end

      it 'creates lteq predicates with <=' do
        predicate = @f <= 1
        predicate.expr.should eq @f
        predicate.method_name.should eq :lteq
        predicate.value.should eq 1
      end

      describe '#as' do

        it 'aliases the function' do
          @f.as('the_alias')
          @f.alias.should eq 'the_alias'
        end

        it 'casts the alias to a string' do
          @f.as(:the_alias)
          @f.alias.should eq 'the_alias'
        end

      end

    end
  end
end