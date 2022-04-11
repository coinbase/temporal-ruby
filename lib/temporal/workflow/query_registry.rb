require 'temporal/errors'

module Temporal
  class Workflow
    class QueryRegistry
      def initialize
        @handlers = {}
      end

      def register(type, &handler)
        if handlers.key?(type)
          warn "[NOTICE] Overwriting a query handler for #{type}"
        end

        handlers[type] = handler
      end

      def handle(type, args = nil)
        handler = handlers[type]

        unless handler
          raise Temporal::QueryFailed, "Workflow did not register a handler for #{type}"
        end

        handler.call(*args)
      end

      private

      attr_reader :handlers
    end
  end
end
