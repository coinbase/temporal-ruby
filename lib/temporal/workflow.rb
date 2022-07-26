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
      puts input.inspect
      require 'json'
      puts input.to_json
      result = workflow.execute(*input)

      context.complete(result) unless context.completed?
    rescue StandardError, ScriptError => e
      Temporal.logger.error('Workflow execution failed', context.metadata.to_h.merge(error: e.inspect))
      Temporal.logger.debug(e.backtrace.join("\n"))

      Temporal::ErrorHandler.handle(e, context.config, metadata: context.metadata)

      context.fail(e)
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
