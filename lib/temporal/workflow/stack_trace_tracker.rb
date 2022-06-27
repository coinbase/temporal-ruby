require 'fiber'

module Temporal
  class Workflow
    # Temporal-web issues a query that returns the stack trace for all workflow fibers
    # that are currently scheduled. This is helpful for understanding what exactly a
    # workflow is waiting on.
    class StackTraceTracker
      STACK_TRACE_QUERY_NAME = '__stack_trace'

      def initialize
        @stack_traces = {}
      end

      # Record the stack trace for the current fiber
      def record
        stack_traces[Fiber.current] = Kernel.caller
      end

      # Clear the stack traces for the current fiber
      def clear
        stack_traces.delete(Fiber.current)
      end

      # Format all recorded backtraces in a human readable format
      def to_s
        formatted_stack_traces = ["Fiber count: #{stack_traces.count}"] + stack_traces.map do |_, stack_trace|
          stack_trace.join("\n")
        end

        formatted_stack_traces.join("\n\n") + "\n"
      end

      private

      attr_reader :stack_traces
    end
  end
end
