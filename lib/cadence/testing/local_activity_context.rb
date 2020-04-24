require 'securerandom'
require 'cadence/uuid'
require 'cadence/activity/context'

module Cadence
  module Testing
    class LocalActivityContext < Activity::Context
      def initialize(metadata)
        super(nil, metadata)
      end

      def heartbeat(details = nil)
        raise NotImplementedError, 'not yet available for testing'
      end
    end
  end
end
