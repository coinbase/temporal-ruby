module Temporal
  class Workflow
    class History
      class Window
        attr_reader :local_time, :last_event_id, :events, :markers

        def initialize
          @local_time = nil
          @last_event_id = nil
          @events = []
          @markers = []
          @replay = false
        end

        def replay?
          @replay
        end

        def add(event)
          case event.type
          when 'MARKER_RECORDED'
            markers << event
          when 'WORKFLOW_TASK_STARTED'
            @last_event_id = event.id + 1 # one for completed
            @local_time = event.timestamp
          when 'WORKFLOW_TASK_FAILED', 'WORKFLOW_TASK_TIMED_OUT'
            @last_event_id = nil
            @local_time = nil
          when 'WORKFLOW_TASK_COMPLETED'
            @replay = true
          when 'WORKFLOW_TASK_SCHEDULED', 'WORKFLOW_TASK_FAILED'
            # no-op
          else
            events << event
          end
        end
      end
    end
  end
end
