require 'cadence/json'

module Cadence
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
          when 'MarkerRecorded'
            markers << [event.id, event.attributes.markerName, JSON.deserialize(event.attributes.details)]
            events << event
          when 'DecisionTaskStarted'
            @last_event_id = event.id + 1 # one for completed
            @local_time = event.timestamp
          when 'DecisionTaskFailed', 'DecisionTaskTimedOut'
            @next_event_id = nil
            @local_time = nil
          when 'DecisionTaskCompleted'
            @replay = true
          when 'DecisionTaskScheduled', 'DecisionTaskFailed'
            # no-op
          else
            events << event
          end
        end
      end
    end
  end
end
