module Cadence
  module Middleware
    class Entry < Struct.new(:klass, :args)
      def init_middleware
        klass.new(*args)
      end
    end
  end
end
