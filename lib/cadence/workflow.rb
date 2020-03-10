require 'cadence/concerns/executable'
require 'cadence/thread_local_context'

module Cadence
  class Workflow
    extend Concerns::Executable

    def self.execute_in_context(context, input)
      Cadence::ThreadLocalContext.set(context)

      workflow = new(context)
      result = workflow.execute(*input)

      context.complete(result)
    rescue StandardError => error
      Cadence.logger.error("Workflow execution failed with: #{error.inspect}")
      Cadence.logger.debug(error.backtrace.join("\n"))

      context.fail(error.class.name, error.message)
    end

    def initialize(context)
      @context = context
    end

    def execute
      raise NotImplementedError, '#execute method must be implemented by a subclass'
    end

    private

    def workflow
      @context
    end

    def logger
      workflow.logger
    end
  end
end
