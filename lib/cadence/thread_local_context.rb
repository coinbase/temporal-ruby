# Provides context for Cadence::Activity::WorkflowConvenienceMethods
module Cadence
  module ThreadLocalContext
    WORKFLOW_CONTEXT_KEY = :cadence_workflow_context

    def self.get
      Thread.current[WORKFLOW_CONTEXT_KEY]
    end

    def self.set(context)
      Thread.current[WORKFLOW_CONTEXT_KEY] = context
    end
  end
end
