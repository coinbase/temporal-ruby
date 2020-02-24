module Cadence
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
          StartChildWorkflowExecutionFailed
          ChildWorkflowExecutionStarted
          ChildWorkflowExecutionCompleted
          ChildWorkflowExecutionFailed
          ChildWorkflowExecutionCanceled
          ChildWorkflowExecutionTimedOut
          ChildWorkflowExecutionTerminated
          SignalExternalWorkflowExecutionFailed
          ExternalWorkflowExecutionCancelRequested
          ExternalWorkflowExecutionSignaled
          UpsertWorkflowSearchAttributes
        ].freeze

        attr_reader :id, :timestamp, :type, :attributes

        def initialize(raw_event)
          @id = raw_event.eventId
          @timestamp = parse_timestamp(raw_event.timestamp)
          @type = CadenceThrift::EventType::VALUE_MAP[raw_event.eventType]
          @attributes = extract_attributes(raw_event)

          freeze
        end

        # Returns the ID of the first event associated with the current event,
        # referred to as a "decision" event. Not related to DecisionTask.
        def decision_id
          case type
          when 'TimerFired'
            attributes.startedEventId
          when 'WorkflowExecutionSignaled'
            1 # fixed id for everything related to current workflow
          when *EVENT_TYPES
            # TODO: this will not work for child workflows
            attributes.scheduledEventId
          else
            id
          end
        end

        private

        def parse_timestamp(timestamp)
          seconds, nanoseconds = timestamp.divmod(1_000_000_000)
          Time.at(seconds, nanoseconds, :nsec)
        end

        def extract_attributes(raw_event)
          attributes_argument = "#{type}EventAttributes"
          attributes_argument[0] = attributes_argument[0].downcase
          raw_event.public_send(attributes_argument)
        end
      end
    end
  end
end
