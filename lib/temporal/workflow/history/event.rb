require 'temporal/utils'

module Temporal
  class Workflow
    class History
      class Event
        EVENT_TYPES = %w[
          ActivityTaskStarted
          ActivityTaskCompleted
          ActivityTaskFailed
          ActivityTaskTimedOut
          ActivityTaskCanceled
          TimerFired
          RequestCancelExternalWorkflowExecutionFailed
          WorkflowExecutionSignaled
          WorkflowExecutionTerminated
          SignalExternalWorkflowExecutionFailed
          ExternalWorkflowExecutionCancelRequested
          ExternalWorkflowExecutionSignaled
          UpsertWorkflowSearchAttributes
        ].freeze

        CHILD_WORKFLOW_EVENTS = %w[
          StartChildWorkflowExecutionFailed
          ChildWorkflowExecutionStarted
          ChildWorkflowExecutionCompleted
          ChildWorkflowExecutionFailed
          ChildWorkflowExecutionCanceled
          ChildWorkflowExecutionTimedOut
          ChildWorkflowExecutionTerminated
        ].freeze

        PREFIX = 'EVENT_TYPE_'.freeze

        attr_reader :id, :timestamp, :type, :attributes

        def initialize(raw_event)
          @id = raw_event.event_id
          @timestamp = Utils.time_from_nanos(raw_event.timestamp)
          @type = raw_event.event_type.to_s.gsub(PREFIX, '')
          @attributes = extract_attributes(raw_event)

          freeze
        end

        # Returns the ID of the first event associated with the current event,
        # referred to as a "decision" event. Not related to DecisionTask.
        def decision_id
          case type
          when 'TimerFired'
            attributes.started_event_id
          when 'WorkflowExecutionSignaled'
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
          attributes_argument = "#{type.downcase}_event_attributes"
          attributes_argument[0] = attributes_argument[0].downcase
          raw_event.public_send(attributes_argument)
        end
      end
    end
  end
end
