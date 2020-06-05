# Provides context for Temporal::Activity::WorkflowConvenienceMethods
module Temporal
  module ThreadLocalContext
    WORKFLOW_CONTEXT_KEY = :temporal_workflow_context

    def self.get
      Thread.current[WORKFLOW_CONTEXT_KEY]
    end

    def self.set(context)
      Thread.current[WORKFLOW_CONTEXT_KEY] = context
    end
  end
end
