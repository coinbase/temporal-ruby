require 'securerandom'
require 'temporal/uuid'
require 'temporal/activity/context'

module Temporal
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
