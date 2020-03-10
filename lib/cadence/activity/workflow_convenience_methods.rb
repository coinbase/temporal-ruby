# This module provides a set of methods for imitating direct Activities calls
# from within Workflows:
#
# class TestWorkflow < Cadence::Workflow
#   def execute
#     TestActivity.execute!('foo', 'bar')
#   end
# end
#
# This is analogous to calling:
#
# workflow.execute_activity(TestActivity, 'foo', 'bar')
#
require 'cadence/thread_local_context'

module Cadence
  class Activity
    module WorkflowConvenienceMethods
      def execute(*input, **args)
        context = Cadence::ThreadLocalContext.get
        raise 'Called Activity#execute outside of a Workflow context' unless context

        context.execute_activity(self, *input, **args)
      end

      def execute!(*input, **args)
        context = Cadence::ThreadLocalContext.get
        raise 'Called Activity#execute! outside of a Workflow context' unless context

        context.execute_activity!(self, *input, **args)
      end

      def execute_locally(*input, **args)
        context = Cadence::ThreadLocalContext.get
        raise 'Called Activity#execute_locally outside of a Workflow context' unless context

        context.execute_local_activity(self, *input, **args)
      end
    end
  end
end
