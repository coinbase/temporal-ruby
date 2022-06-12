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
          # The end of the formatted error message (e.g., "KnownQueryTypes=[query-1, query-2, query-3]")
          # is used by temporal-web to show a list of queries that can be run on the 'Query' tab of a
          # workflow. If that part of the error message is changed, that functionality will break.
          raise Temporal::QueryFailed, "Workflow did not register a handler for '#{type}'. KnownQueryTypes=[#{handlers.keys.join(", ")}]"
        end

        handler.call(*args)
      end

      private

      attr_reader :handlers
    end
  end
end
