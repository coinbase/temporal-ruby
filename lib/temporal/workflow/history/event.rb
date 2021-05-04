module Temporal
  class Workflow
    class History
      class Event
        EVENT_TYPES = %w[
          ACTIVITY_TASK_STARTED
          ACTIVITY_TASK_COMPLETED
          ACTIVITY_TASK_FAILED
          ACTIVITY_TASK_TIMED_OUT
          ACTIVITY_TASK_CANCELED
          TIMER_FIRED
          REQUEST_CANCEL_EXTERNAL_WORKFLOW_EXECUTION_FAILED
          SIGNAL_EXTERNAL_WORKFLOW_EXECUTION_FAILED
          EXTERNAL_WORKFLOW_EXECUTION_CANCEL_REQUESTED
          EXTERNAL_WORKFLOW_EXECUTION_SIGNALED
          UPSERT_WORKFLOW_SEARCH_ATTRIBUTES
        ].freeze

        CHILD_WORKFLOW_EVENTS = %w[
          START_CHILD_WORKFLOW_EXECUTION_FAILED
          CHILD_WORKFLOW_EXECUTION_STARTED
          CHILD_WORKFLOW_EXECUTION_COMPLETED
          CHILD_WORKFLOW_EXECUTION_FAILED
          CHILD_WORKFLOW_EXECUTION_CANCELED
          CHILD_WORKFLOW_EXECUTION_TIMED_OUT
          CHILD_WORKFLOW_EXECUTION_TERMINATED
        ].freeze

        PREFIX = 'EVENT_TYPE_'.freeze

        attr_reader :id, :timestamp, :type, :attributes

        def initialize(raw_event)
          @id = raw_event.event_id
          @timestamp = raw_event.event_time.to_time
          @type = raw_event.event_type.to_s.gsub(PREFIX, '')
          @attributes = extract_attributes(raw_event)

          freeze
        end

        # Returns the ID of the first event associated with the current event.
        def originating_event_id
          case type
          when 'TIMER_FIRED'
            attributes.started_event_id
          when 'WORKFLOW_EXECUTION_SIGNALED', 'WORKFLOW_EXECUTION_TERMINATED'
            1 # fixed id for everything related to current workflow
          when *EVENT_TYPES
            attributes.scheduled_event_id
          when *CHILD_WORKFLOW_EVENTS
            attributes.initiated_event_id
          else
            id
          end
        end

        private

        def extract_attributes(raw_event)
          attributes_name = raw_event.attributes
          raw_event.public_send(attributes_name)
        end
      end
    end
  end
end
