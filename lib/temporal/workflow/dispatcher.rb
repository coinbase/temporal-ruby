module Temporal
  class Workflow
    class Dispatcher
      WILDCARD = '*'.freeze
      TARGET_WILDCARD = '*'.freeze

      def initialize
        @handlers = Hash.new { |hash, key| hash[key] = [] }
        @query_handlers = Hash.new { |hash, key| hash[key] = {} }
      end

      def register_handler(target, event_name, &handler)
        handlers[target] << [event_name, handler]
      end

      def register_query_handler(target, query, &handler)
        query_handlers[target][query] = handler
      end

      def dispatch(target, event_name, args = nil)
        handlers_for(target, event_name).each do |handler|
          handler.call(*args)
        end
      end

      def process_query(target, query, args)
        if query == '__cadence_web_list'
          return query_handlers[target].keys + %w[__stack_trace]
        end
        query_handlers[target][query].call(*args)
      end

      private

      attr_reader :handlers, :query_handlers

      def handlers_for(target, event_name)
        handlers[target]
          .concat(handlers[TARGET_WILDCARD])
          .select { |(name, _)| name == event_name || name == WILDCARD }
          .map(&:last)
      end
    end
  end
end
