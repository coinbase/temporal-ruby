require 'temporal/errors'

module Temporal
  class Workflow
    # This provides a generic event dispatcher mechanism. There are two main entry
    # points to this class, #register_handler and #dispatch.
    #
    # A handler may be associated with a specific event name so when that event occurs
    # elsewhere in the system we may dispatch the event and execute the handler.
    # We *always* execute the handler associated with the event_name.
    #
    class Dispatcher
      # Raised if a duplicate ID is encountered during dispatch handling.
      # This likely indicates a bug in temporal-ruby or that unsupported multithreaded
      # workflow code is being used.
      class DuplicateIDError < InternalError; end

      # Tracks a registered handle so that it can be unregistered later
      # The handlers are passed by reference here to be mutated (removed) by the
      # unregister call below.
      class RegistrationHandle
        def initialize(handlers_for_target, id)
          @handlers_for_target = handlers_for_target
          @id = id
        end

        # Unregister the handler from the dispatcher
        def unregister
          handlers_for_target.delete(id)
        end

        private

        attr_reader :handlers_for_target, :id
      end

      WILDCARD = '*'.freeze

      module Order
        AT_BEGINNING = 1
        AT_END = 2
      end

      EventStruct = Struct.new(:event_name, :handler, :order)

      def initialize
        @event_handlers = Hash.new { |hash, key| hash[key] = {} }
        @next_id = 0
      end

      def register_handler(target, event_name, order=Order::AT_BEGINNING, &handler)
        @next_id += 1
        event_handlers[target][@next_id] = EventStruct.new(event_name, handler, order)
        RegistrationHandle.new(event_handlers[target], @next_id)
      end

      def dispatch(target, event_name, args = nil)
        handlers_for(target, event_name).each do |handler|
          handler.call(*args)
        end
      end

      private

      attr_reader :event_handlers

      def handlers_for(target, event_name)
        event_handlers[target]
          .merge(event_handlers[WILDCARD]) { raise DuplicateIDError.new('Cannot resolve duplicate dispatcher handler IDs') }
          .select { |_, event| match?(event, event_name) }
          .sort_by{ |id, event_struct| [event_struct.order, id]}
          .map { |_, event| event.handler }
      end

      def match?(event_struct, event_name)
        event_struct.event_name == event_name ||
          event_struct.event_name == WILDCARD
      end
    end
  end
end
