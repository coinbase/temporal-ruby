require 'securerandom'
require 'cadence/uuid'

module Cadence
  module Testing
    class LocalActivityContext
      attr_reader :run_idem, :workflow_idem, :headers

      alias idem run_idem

      def initialize(run_id, workflow_id, headers: {})
        activity_id = SecureRandom.uuid

        @run_idem = UUID.v5(run_id, activity_id)
        @workflow_idem = UUID.v5(workflow_id, activity_id)
        @headers = headers
      end

      def logger
        Cadence.logger
      end

      def heartbeat(details = nil)
        raise NotImplementedError, 'not yet available for testing'
      end
    end
  end
end
