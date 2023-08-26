require 'set'
require 'temporal/workflow/sdk_flags'

module Temporal
  class Workflow
    class History
      class Window
        attr_reader :local_time, :last_event_id, :events, :sdk_flags

        def initialize
          @local_time = nil
          @last_event_id = nil
          @events = []
          @replay = false
          @sdk_flags = Set.new
        end

        def replay?
          @replay
        end

        def add(event)
          case event.type
          when 'WORKFLOW_TASK_STARTED'
            @last_event_id = event.id + 1 # one for completed
            @local_time = event.timestamp
          when 'WORKFLOW_TASK_FAILED', 'WORKFLOW_TASK_TIMED_OUT'
            @last_event_id = nil
            @local_time = nil
          when 'WORKFLOW_TASK_COMPLETED'
            @replay = true
            used_flags = Set.new(event.attributes&.sdk_metadata&.lang_used_flags)
            unknown_flags = used_flags.difference(SDKFlags::ALL)
            raise Temporal::UnknownSDKFlagError, "Unknown SDK flags: #{unknown_flags.join(',')}" if unknown_flags.any?

            used_flags.each { |flag| sdk_flags.add(flag) }
          when 'WORKFLOW_TASK_SCHEDULED'
            # no-op
          else
            events << event
          end
        end
      end
    end
  end
end
