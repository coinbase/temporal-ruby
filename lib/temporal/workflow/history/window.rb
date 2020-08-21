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
          case event.type.to_s
          when 'MARKER_RECORDED'
            markers << event
          when 'DECISION_TASK_STARTED'
            @last_event_id = event.id + 1 # one for completed
            @local_time = event.timestamp
          when 'DECISION_TASK_FAILED', 'DECISION_TASK_TIMED_OUT'
            @next_event_id = nil
            @local_time = nil
          when 'DECISION_TASK_COMPLETED'
            @replay = true
          when 'DECISION_TASK_SCHEDULED', 'DECISION_TASK_FAILED'
            # no-op
          else
            events << event
          end
        end
      end
    end
  end
end
