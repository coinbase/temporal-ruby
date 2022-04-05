module Temporal
  class Workflow
    # This provides a generic event dispatcher mechanism. There are two main entry
    # points to this class, #register_handler and #dispatch.
    #
    # A handler may be associated with a specific event name so when that event occurs
    # elsewhere in the system we may dispatch the event and execute the handler.
    # We *always* execute the handler associated with the event_name.
    #
    # Optionally, we may register a named handler that is triggered when an event _and
    # an optional handler_name key_ are provided. In this situation, we dispatch to both
    # the handler associated to event_name+handler_name and to the handler associated with
    # the event_name. The order of this dispatch is not guaranteed.
    #
    class Dispatcher
      WILDCARD = '*'.freeze
      TARGET_WILDCARD = '*'.freeze

      EventStruct = Struct.new(:event_name, :handler)

      def initialize
        @handlers = Hash.new { |hash, key| hash[key] = [] }
      end

      def register_handler(target, event_name, &handler)
        handlers[target] << EventStruct.new(event_name, handler)
        self
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
          .select { |event_struct| match?(event_struct, event_name) }
          .map(&:handler)
      end

      def match?(event_struct, event_name)
        event_struct.event_name == event_name ||
          event_struct.event_name == WILDCARD
      end
    end
  end
end
