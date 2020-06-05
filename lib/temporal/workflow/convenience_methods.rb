# This module provides a set of methods for imitating direct Child Workflow calls
# from within Workflows:
#
# class TestWorkflow < Temporal::Workflow
#   def execute
#     ChildWorkflow.execute!('foo', 'bar')
#   end
# end
#
# This is analogous to calling:
#
# workflow.execute_workflow(ChildWorkflow, 'foo', 'bar')
#
require 'temporal/thread_local_context'

module Temporal
  class Workflow
    module ConvenienceMethods
      def execute(*input, **args)
        context = Temporal::ThreadLocalContext.get
        raise 'Called Workflow#execute outside of a Workflow context' unless context

        context.execute_workflow(self, *input, **args)
      end

      def execute!(*input, **args)
        context = Temporal::ThreadLocalContext.get
        raise 'Called Workflow#execute! outside of a Workflow context' unless context

        context.execute_workflow!(self, *input, **args)
      end
    end
  end
end
