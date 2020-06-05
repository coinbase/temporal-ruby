module Temporal
  module Testing
    class FutureRegistry
      def initialize
        @store = {}
      end

      def register(token, future)
        raise 'already registered' if store.key?(token)

        store[token] = future
      end

      def complete(token, result)
        store[token].set(result)
      end

      def fail(token, error)
        store[token].fail(error.class.name, error.message)
      end

      private

      attr_reader :store
    end
  end
end
