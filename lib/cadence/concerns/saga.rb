require 'cadence/workflow/saga'

module Cadence
  module Concerns
    module Saga
      def run_saga(&block)
        saga = Cadence::Workflow::Saga.new(workflow)

        block.call(saga)
      rescue StandardError => error # TODO: is there a need for a specialized error here?
        logger.error("Saga execution aborted: #{error.inspect}")
        logger.debug(error.backtrace.join("\n"))

        saga.compensate
      end
    end
  end
end
