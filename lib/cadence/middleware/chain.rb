module Cadence
  module Middleware
    class Chain
      def initialize(entries = [])
        @middleware = entries.map(&:init_middleware)
      end

      def invoke(metadata)
        result = nil
        chain = middleware.dup

        traverse_chain = lambda do
          if chain.empty?
            result = yield
          else
            chain.shift.call(metadata, &traverse_chain)
          end
        end

        traverse_chain.call

        result
      end

      private

      attr_reader :middleware
    end
  end
end
