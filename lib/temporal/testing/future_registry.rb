module Temporal
  module Testing
    class FutureRegistry
      def initialize
        @store = {}
      end

      def register(id, future)
        raise 'already registered' if store.key?(id.to_s)

        store[id.to_s] = future
      end

      def complete(id, result)
        future = store[id.to_s]
        future.set(result)
        future.success_callbacks.each { |callback| callback.call(result) }
      end

      def fail(id, error)
        future = store[id.to_s]
        future.fail(error)
        future.failure_callbacks.each{ |callback| callback.call(result) }
      end

      private

      attr_reader :store
    end
  end
end
