require 'temporal/activity/context'

module Temporal
  module Testing
    class LocalActivityContext < Activity::Context
      def initialize(metadata)
        super(nil, metadata, nil, nil, proc { false })
      end

      def heartbeat(details = nil)
        # behavior is not yet testable in local mode
      end

      def heartbeat_interrupted(details = nil)
        # behavior is not yet testable in local mode
      end

      def timed_out?
        # behavior is not yet testable in local mode
        false
      end

      def shutting_down?
        # behavior is not yet testable in local mode
        false
      end
    end
  end
end
