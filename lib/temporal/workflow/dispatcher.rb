module Temporal
  class Workflow
    class Dispatcher
      WILDCARD = '*'.freeze
      TARGET_WILDCARD = '*'.freeze

      def initialize
        @handlers = Hash.new { |hash, key| hash[key] = [] }
        @next_id = 1
      end

      def register_handler(target, event_name, &handler)
        handlers[target] << [@next_id, event_name, handler]
        @next_id += 1
      end

      def dispatch(target, event_name, args = nil)
        handlers_for(target, event_name).each do |handler|
          handler.call(*args)
        end
      end

      private

      attr_reader :handlers

      def handlers_for(target, event_name)
        handlers[target]
          .concat(handlers[TARGET_WILDCARD])
          .select { |(_, name, _)| name == event_name || name == WILDCARD }
          .sort_by { |sequence, _, _| sequence }
          .map(&:last)
      end
    end
  end
end
