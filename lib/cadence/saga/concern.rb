require 'cadence/saga/saga'
require 'cadence/saga/result'

module Cadence
  module Saga
    module Concern
      def run_saga(&block)
        saga = Cadence::Saga::Saga.new(workflow)

        block.call(saga)

        Result.new(true)
      rescue StandardError => error # TODO: is there a need for a specialized error here?
        logger.error("Saga execution aborted: #{error.inspect}")
        logger.debug(error.backtrace.join("\n"))

        saga.compensate

        Result.new(false, error)
      end
    end
  end
end
