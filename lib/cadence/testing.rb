require 'cadence/testing/cadence_override'
require 'cadence/testing/workflow_override'

module Cadence
  module Testing
    DISABLED_MODE = nil
    LOCAL_MODE = :local

    class << self
      def local!(&block)
        set_mode(LOCAL_MODE, &block)
      end

      def disabled!(&block)
        set_mode(DISABLED_MODE, &block)
      end

      def disabled?
        mode == DISABLED_MODE
      end

      def local?
        mode == LOCAL_MODE
      end

      private

      attr_reader :mode

      def set_mode(new_mode, &block)
        if block_given?
          with_mode(new_mode, &block)
        else
          @mode = new_mode
        end
      end

      def with_mode(new_mode, &block)
        previous_mode = mode
        @mode = new_mode
        yield
      ensure
        @mode = previous_mode
      end
    end
  end
end

Cadence.singleton_class.prepend Cadence::Testing::CadenceOverride
Cadence::Workflow.extend Cadence::Testing::WorkflowOverride
