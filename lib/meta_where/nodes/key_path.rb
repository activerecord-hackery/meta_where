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
        else
          endpoint % val
        end
      end

      def path_with_endpoint
        path + [endpoint]
      end

      def to_s
        path.map(&:to_s).join('.') << ".#{endpoint}"
      end

      def method_missing(method_id, *args)
        super unless Stub === endpoint

        if endpoint.respond_to? method_id
          @endpoint = @endpoint.send(method_id, *args)
          self
        else
          @path << endpoint.symbol
          @endpoint = Stub.new(method_id)
          self
        end
      end

    end
  end
end