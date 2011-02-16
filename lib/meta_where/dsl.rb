module MetaWhere
  class DSL

    original_verbosity = $VERBOSE
    $VERBOSE = nil
    (instance_methods + private_instance_methods).each do |method|
      unless method.to_s =~ /^(__|instance_eval)/
        undef_method method
      end
    end
    $VERBOSE = original_verbosity

    def self.evaluate(&block)
      self.new.instance_eval(&block)
    end

    def method_missing(method_id, *args)
      if args.empty?
        Nodes::Stub.new method_id
      elsif (args.size == 1) && (Class === args[0])
        Nodes::Join.new(method_id, Arel::InnerJoin, args[0])
      else
        Nodes::Function.new :method_id, args
      end
    end

  end
end