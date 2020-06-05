module Temporal
  class Workflow
    class Dispatcher
      WILDCARD = '*'.freeze

      def initialize
        @handlers = Hash.new { |hash, key| hash[key] = [] }
      end

      def register_handler(target, event_name, &handler)
        handlers[target] << [event_name, handler]
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
          .select { |(name, _)| name == event_name || name == WILDCARD }
          .map(&:last)
      end
    end
  end
end
