module Temporal
  class Workflow
    # This provides a generic event dispatcher mechanism. There are two main entry
    # points to this class, #register_handler and #dispatch.
    #
    # A handler may be associated with a specific event name so when that event occurs
    # elsewhere in the system we may dispatch the event and execute the handler. By default
    # we do a simple name <=> handler association.
    #
    # Optionally, we may register a named handler that is triggered when an event _and
    # an optional handler_name key_ are provided. When this more specific match
    # fails, we fall back to matching just against +event_name+.
    #
    class Dispatcher
      WILDCARD = '*'.freeze
      TARGET_WILDCARD = '*'.freeze

      EventStruct = Struct.new(:event_name, :handler, :handler_name)
      DuplicateNamedHandlerRegistrationError = Class.new(StandardError)

      def initialize
        @handlers = Hash.new { |hash, key| hash[key] = [] }
      end

      def register_handler(target, event_name, handler_name: nil, &handler)
        if handler_name && find_named_handler(target, event_name, handler_name)
          raise DuplicateNamedHandlerRegistrationError.new("Duplicate registration for handler_name #{handler_name}")
        end

        handlers[target] << EventStruct.new(event_name, handler, handler_name)
        self
      end

      def dispatch(target, event_name, args = nil, handler_name: nil)
        handlers_for(target, event_name, handler_name).each do |handler|
          handler.call(*args)
        end
      end

      private

      attr_reader :handlers

      def handlers_for(target, event_name, handler_name)
        if handler_name
          struct = find_named_handler(target, event_name, handler_name)
          return [struct.handler] if struct
        end

        # specific match failed or was not provided, fall back to default behavior
        # and filter out named handlers
        handlers[target]
          .select { |event_struct| event_struct.handler_name.nil? }
          .concat(handlers[TARGET_WILDCARD])
          .select { |event_struct| event_struct.event_name == event_name || event_struct.event_name == WILDCARD }
          .map(&:handler)
      end

      def find_named_handler(target, event_name, handler_name)
        # to succeed then +handler_name+ must be non-nil
        handlers[target]
          .find do |event_struct|
          handler_name &&
            event_struct.event_name == event_name &&
            event_struct.handler_name == handler_name
        end
      end
    end
  end
end
