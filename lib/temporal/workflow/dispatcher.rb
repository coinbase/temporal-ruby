module Temporal
  class Workflow
    class Dispatcher
      WILDCARD = '*'.freeze
      TARGET_WILDCARD = '*'.freeze

      def initialize
        @handlers = Hash.new { |hash, key| hash[key] = [] }
      end

      def register_handler(target, event_name, &handler)
        handlers[target] << [event_name, handler]
      end

      def dispatch(target, event_name, args = nil)
        handlers_for(target, event_name).each do |_, handler|
          handler.call(*args)
        end
      end

      def process(target, event_name, args = nil)
        registered_name, handler = handlers_for(target, event_name).first
        unless handler.nil?
          args = [args] unless args.is_a?(Array)
          args.unshift(event_name) if registered_name == WILDCARD
          handler.call(*args)
        end
      end

      private

      attr_reader :handlers

      def handlers_for(target, event_name)
        handlers[target]
          .concat(handlers[TARGET_WILDCARD])
          .select { |(name, _)| name == event_name || name == WILDCARD }
          .sort_by { |(name, _)| name == WILDCARD ? 1 : 0 }
      end
    end
  end
end
