require 'temporal/activity/workflow_convenience_methods'
require 'temporal/concerns/executable'
require 'temporal/errors'

module Temporal
  class Activity
    extend WorkflowConvenienceMethods
    extend Concerns::Executable

    def self.execute_in_context(context, input)
      activity = new(context)
      activity.execute(*input)
    end

    def initialize(context)
      @context = context
    end

    def execute(*_args)
      raise NotImplementedError, '#execute method must be implemented by a subclass'
    end

    private

    def activity
      @context
    end

    def logger
      activity.logger
    end
  end
end
