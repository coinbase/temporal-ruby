require 'temporal/concerns/executable'
require 'temporal/workflow/convenience_methods'
require 'temporal/thread_local_context'
require 'temporal/error_handler'

module Temporal
  class Workflow
    extend Concerns::Executable
    extend ConvenienceMethods

    def self.execute_in_context(context, input)
      old_context = Temporal::ThreadLocalContext.get
      Temporal::ThreadLocalContext.set(context)

      workflow = new(context)
      result = workflow.execute(*input)

      context.complete(result) unless context.completed?
    rescue FailWorkflowTaskError => error
      Temporal.logger.error("Workflow requested to fail the workflow task: #{error.inspect}")
      Temporal::ErrorHandler.handle(error, metadata: context.metadata)

      # Rethrowing the exception fails the workflow task as opposed to failing the entire
      # workflow. Temporal will then retry this task until it succeeds or a timeout limit is reached.
      # This stands in contrast to the next rescue block that will cause the entire workflow to
      # be failed for all other kinds of StandardErrors.
      raise
    rescue StandardError, ScriptError => error
      Temporal.logger.error("Workflow execution failed with: #{error.inspect}")
      Temporal.logger.debug(error.backtrace.join("\n"))

      Temporal::ErrorHandler.handle(error, metadata: context.metadata)

      context.fail(error)
    ensure
      Temporal::ThreadLocalContext.set(old_context)
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
