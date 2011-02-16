require 'singleton'

module MetaWhere
  module Builders
    class StubBuilder

      original_verbosity = $VERBOSE
      $VERBOSE = nil
      (instance_methods + private_instance_methods).each do |method|
        unless method.to_s =~ /^(__|instance_eval)/
          undef_method method
        end
      end
      $VERBOSE = original_verbosity

      def self.build(&block)
        self.new.instance_eval(&block)
      end

      def method_missing(method_id, *args)
        Nodes::Stub.new method_id
      end

    end
  end
end