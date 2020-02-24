require 'cadence/activity/workflow_convenience_methods'
require 'cadence/concerns/executable'
require 'cadence/errors'

module Cadence
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
