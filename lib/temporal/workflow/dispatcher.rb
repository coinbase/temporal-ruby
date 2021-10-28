module Temporal
  class Workflow
    class Dispatcher
      WILDCARD = '*'.freeze

      def initialize
        @handlers = Hash.new { |hash, key| hash[key] = [] }
        @await_handler = nil
      end

      def register_handler(target, event_name, &handler)
        handlers[target] << [event_name, handler]
      end

      def register_await_handler(&handler)
        # This should only happen in situations where multithreading is being used
        # in workflow code which is unsupported.
        raise 'Await handler already active' unless await_handler.nil?

        @await_handler = handler
      end

      def dispatch(target, event_name, args = nil)
        handlers_for(target, event_name).each do |handler|
          handler.call(*args)
        end

        return if await_handler.nil?

        # Any await handler whose condition evaluates to true must be removed. Its fiber has now
        # been resumed and should not be resumed again by other dispatch calls.
        unset_await_handler = proc { @await_handler = nil }

        # Invoking the await handler needs to be done after target-specific handlers
        # because an activity, sleep, or signal may have completed that affects the state
        # evaluated in an await condition.
        await_handler.call(unset_await_handler)
      end

      private

      attr_reader :await_handler, :handlers

      def handlers_for(target, event_name)
        handlers[target]
          .select { |(name, _)| name == event_name || name == WILDCARD }
          .map(&:last)
      end
    end
  end
end
