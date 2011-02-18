module MetaWhere
  module Nodes
    class KeyPath

      attr_reader :path, :endpoint

      def initialize(path, endpoint)
        @path, @endpoint = path, endpoint
        @path = [@path] unless Array === @path
        @endpoint = Stub.new(@endpoint) if Symbol === @endpoint
      end

      def eql?(other)
        self.class == other.class &&
        self.path == other.path &&
        self.endpoint.eql?(other.endpoint)
      end

      undef :==   # To let it fall through to Stub#method_missing

      def hash
        [self.class, endpoint, *path].hash
      end

      def to_sym
        nil
      end

      def %(val)
        case endpoint
        when Stub, Function
          eq(val)
          self
        else
          endpoint % val
          self
        end
      end

      def path_with_endpoint
        path + [endpoint]
      end

      def to_s
        path.map(&:to_s).join('.') << ".#{endpoint}"
      end

      def method_missing(method_id, *args)
        if endpoint.respond_to? method_id
          @endpoint = @endpoint.send(method_id, *args)
          self
        elsif Stub === endpoint
          @path << endpoint.symbol
          if args.empty?
            @endpoint = Stub.new(method_id)
          elsif (args.size == 1) && (Class === args[0])
            @endpoint = Join.new(method_id, Arel::InnerJoin, args[0])
          else
            @endpoint = Nodes::Function.new method_id, args
          end
          self
        else
          super
        end
      end

    end
  end
end